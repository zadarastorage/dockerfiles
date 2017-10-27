#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <dirent.h>
#include <cstring>
#include <stdlib.h>
#include <string>
#include <time.h>
#include <cerrno>
#include <fcntl.h>
#include <unistd.h>


using namespace std;


static
long long	bytes_copied = 0;

static
long long	copied_count = 0;

static
unsigned	verbose = 0;


char * trim_slash (char *dir)
{
	int i = strlen (dir);

	while (i > 1) {

		if ( dir[--i] == '/')
		{
			dir[i] = 0;
		}
		else
			break;
	}

	return dir;

}

/**
 *
 * do_mkdir
 *
 * Create parent directories as required for the destination archived file
 * or, mkdir -p
 *
 */

int do_mkdir (string dir, mode_t mode)
{
	unsigned	i, j, k;
	unsigned	len;

	struct stat	sbuf;

	if (stat (dir.c_str(), &sbuf) == -1)
	{

		if (errno == ENOENT) 
		{

			// mkdir -p first

			len = dir.length();

			if (verbose)
				printf ("not found: %s\n", dir.c_str());


			i = k = 0;
			
			while (i < len)
			{
				j = 0;

				while ( (i+j) < len && dir[i+j] == '/' )
					j++;

				if ( j == 1 )
				{
					if (verbose)
						printf ("%s\n", dir.substr(k, i-k).c_str() );

					if (stat (dir.substr(k, i-k).c_str(), &sbuf) == -1)
					{
						mkdir (dir.substr(k, i-k).c_str(), mode);
					}


				}
				i++;
				
			} // mkdir -p


			// create the directory

			mkdir (dir.c_str(), mode);




			return 0;

		}
		else {

			char buff [256];
			printf ("mkdir: %d %s\n", 
				errno,
				strerror_r ( errno, buff, sizeof(buff)-1) );


			return -1;
		}


	}

	if ( !(sbuf.st_mode & S_IFDIR) )
	{
		printf ("%s not a dir\n", dir.c_str());
		return -1;
	}

	if (verbose)
		printf("%s found\n", dir.c_str());

	return 1;


}


/**
 * copy_file from src to dst
 * 
 */

int copy_file (string src, string dst)
{
//	For now, let rsync do all the work...

	FILE*	fp_rsync;
	string		rsync = "rsync -avAX " + src + " " + dst;

	char		cmd [8192];
	unsigned	i;
	unsigned	len;
	int			dump = 0;

	strcpy (cmd, "rsync -avAX ");
	
	len	= strlen (cmd);

	for (i = 0; (i < src.length()) && (len < sizeof(cmd)-2); i++)
	{
		if (src[i] == ' ')
		{
			cmd[len++] = '\\';
			dump = 1;
		}

		cmd[len++] = src[i];
	}

	cmd[len++] = ' ';

	for (i = 0; (i < dst.length()) && (len < sizeof(cmd)-2); i++)
	{
		if (dst[i] == ' ')
		{
			cmd[len++] = '\\';
			dump = 1;
		}
		cmd[len++] = dst[i];
	}
	cmd[len] = 0;

	if (dump && verbose)
		printf ("%s\n", cmd);

	if (len >= sizeof(cmd)) return -1;

	fp_rsync = popen (cmd, "r");
	if (fp_rsync)
	{
		char line[512];
		if (verbose) {
			printf ("copy %s to %s\n", src.c_str(), dst.c_str());
			while (fgets (line, sizeof(line)-1, fp_rsync ) != NULL)
			{
				printf("%s", line);
			}
		}

		pclose (fp_rsync);
		return 0;
	}
	else {
//		TODO: rsync error

		printf ("rsync error\n");
	}

	return -1;

}


int listdir( std::string dir, string destdir, int depth, time_t age) {

	DIR				*dp;
	struct dirent	*ep;

	struct stat		sbuf;
	struct stat		sobuf;


	int				mkdir = 0;	// for updating parent dir with correct permissions.
	string			oname;

	dp = opendir(dir.c_str());
	
	if (dp) {

		string destname;

		while ( (ep = readdir(dp)) ) {

			std::string name = dir+"/"+std::string(ep->d_name);

			if (stat (name.c_str(), &sbuf) == -1) continue;			// TODO: Process error

			// Handle type for file systems (e.g. XFS) not supporting d_type

			if (ep->d_type == DT_UNKNOWN)
			{
				if (S_ISDIR(sbuf.st_mode))
					ep->d_type = DT_DIR;
				else if (S_ISREG(sbuf.st_mode))
					ep->d_type = DT_REG;
			}
	
			switch (ep->d_type) {

			case DT_DIR:

				if (ep->d_name[0] == '.') break;

				destname = destdir + "/"+ string(ep->d_name);

				mkdir += listdir(name, destname, depth+1, age);

				break;

			case DT_REG:


				if (age < sbuf.st_mtime) break;

				if (!mkdir) {

					mode_t mode =  S_IRWXU|S_IRWXG|S_IXOTH|S_IROTH;

					if ( do_mkdir (destdir, mode) == -1)
					{
						printf ("skipping\n");
						continue; // fatal
					}
				
					mkdir++;

				}

				oname = destdir+"/"+string(ep->d_name);


				if (stat (oname.c_str(), &sobuf) == -1) {

// 					Not Found
					if (copy_file (name, oname) < 0) break;
				
					bytes_copied += (long long)sbuf.st_size;
					copied_count++;
				}
				else if ((sbuf.st_mtime != sobuf.st_mtime) || (sbuf.st_size != sobuf.st_size))
				{
					if (copy_file (name, oname) < 0) break;
				
					bytes_copied += (long long)sbuf.st_size;
					copied_count++;
	
				}
				else if (verbose) {
					printf ("skipping %s\n", name.c_str());
				}



				break;

			default:
				break;
			}

		}

		closedir(dp);
	}

	return mkdir;

}


void usage () {

	const char * msg = 
"NAME\n\
	zage - Zadara Aging\n\n\
\
SYNOPSIS\n\
	zage [OPTION]... [SOURCE] [DESTINATION]\n\n\
\
DESCRIPTION\n\
\
	Moves files from [SOURCE] to [DESTINATION] or removes [DESTINATION] files based on age.\n\n\
\
Usage: zage <options> src dest\n\	
	-d [DAYS]\t Delete destination files if older than [DAYS]\n\
	-a [DAYS]\t Moves source files to destination if older than [DAYS]\n\
	-s dir\t Defines the root source directory\n\
	-e dir\t Defines the root destination directory\n\
	-t [THREADS]\t Defines the number of threads to run\n";

	printf ("%s", msg);

/// -L logfile

}



int main (int argc, char **argv, char **argp) 
{

	int		i;
	int		a_days 	= 0;
	int		d_days 	= 0;
	int		threads	= 1;
	char*	src		= 0;
	char*	dest 	= 0;
	time_t	now;

	struct timeval 	tv_start;
	struct timeval	tv_end;

	if (argc < 2) 
	{
		usage();
		return 1;
	}



	for (i = 1; i < argc; i++)
	{
		char * 	arg = argv[i];

		if (!arg) continue;

		if (arg[0] == '-')
		{
			char option;

			arg++;
			option = *arg;

			i++;
			if (i >= argc) continue;

			arg = argv[i];
			if (!arg) continue;


			switch (option)
			{

			case 'a':
			
				// archive: -a [DAYS]

				sscanf (arg, "%d", &a_days);
				
				break;

			case 'd':

				// delete: -d [DAYS]

				sscanf (arg, "%d", &d_days);

				break;

			case 'e':

				// destination -e Destination

				dest = trim_slash (arg);
				break;

			case 'h':

				usage();
				return 1;

			case 's':
		
				// source: -S Source

				src = trim_slash (arg);
				break;

			case 't':

				// threads: -t [COUNT]

				sscanf (arg, "%d", &threads);
				break;

			case 'v':
				verbose++;
				break;

			default:
				break;
			}

			continue;
		}

	} // for i


	now = time (NULL);
	gettimeofday (&tv_start, NULL);

	if (a_days > 0 && src && dest)
		listdir ( src,  dest, 0, now - (24*3600*a_days) );

	if (d_days > 0 && dest)
		listdir ( dest, dest, 0, now - (24*3600*d_days) );

	gettimeofday (&tv_end, NULL);

	double dt = ( (double)(tv_end.tv_sec - tv_start.tv_sec) * 1.e6 + (double)(tv_end.tv_usec - tv_start.tv_usec) ) * 1.e-6;

	printf ("a_days=%d d_days=%d %lld %lld MB/s = %f\n", a_days, d_days, bytes_copied, copied_count, (double)bytes_copied / dt);

	return 0;
}
