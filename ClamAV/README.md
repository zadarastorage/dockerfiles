# ClamAV

ClamAV is a mature open source AntiVirus solution for Linux.  This container utilizes iNotify to monitor changes in file shares which then feed the files to the ClamAV service for virus scanning.  Infected files are sent to quarantine and events are logged.  

A list of virus definitions can be installed at build time however to keep definitions current it is best add a proxy to allow freshclam to update these regularly.  (example of adding Squid proxy below)


## Use Case

This Dockerfile can be adapted by an administrator to scan directories in various shares as they are updated and quarantine files without affecting performance.


## SSH

This Dockerfile also adds SSH daemon support in the event the administrator wishes to login to the container remotely to do any troubleshooting.  This is optional and can be disabled by commenting out the appropriate sections in the Dockerfile.  **If you do choose to retain SSH access, please change the root password ASAP.**



## Creating The Container

Some screenshots are included below to explain how to create this container with all required settings on Zadara Container Services.

### Ports

If you wish to access this container via SSH, specify that port 22 should be accessible:

![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/ClamAV/screenshots/add_port.png)

### Volumes

You need to specify which Zadara NAS Share volume(s) will be mounted in the container.  There can be a single or multiple shares mounted for scanning, logging and quarantine.  In this case we are just using 'nas-1' mounted as '/mnt/ex_scan_vol' and 'nas-2' mounted as '/mnt/ex_log_vol':

![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/ClamAV/screenshots/add_vol.png)

### Environment Variables

These variables allow you to specify your proxy as well as scan, quarantine and log directories residing on the mounted drives: 


**(optional)**
 - PROXY_SERVER - IP Address to the proxy server allowing access to download virus definition updates accessible through an instance on your AWS VPC
 - PROXY_PORT - Port number to the proxy server allowing access to download virus definition updates accessible through an instance on your AWS VPC
 - DEF_UPD_FREQ - The frequency in which to download the virus definitions updates per day (default is 24)

**(required)**
 - SCAN_PATH - The path(s) to the added volume in which to scan.  Multiple paths are simply separated by a space.
 - QUAR_PATH - The path to the added volume in which infected files are moved to.
 - LOG_PATH - The path for log output.  'clamav-clamd.log', 'clamav-freshclamd.log' and 'clamav-scans.log' are sent to this directory.

![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/ClamAV/screenshots/add_env_variables.png)

### Entry Point

Not required

## SQUID PROXY (optional)

ClamAV docker container -> squid proxy ec2 instance -> Internet

The Squid proxy is used to allow for virus definitions to be retrieved from the internet by the docker container.  Currently our container service does not have direct internet access however since the containers can communicate with the VPC attached to your VPSA, a proxy to the internet can be setup on an EC2 instance. 


The instance will not need a lot of local storage, so the default amount (8GB as of this writing) should be ok.

## AWS
Make sure to allow 3128 from IP Range of the VPSA on the EC2 instance security group.
	
![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/ClamAV/screenshots/aws_sec_group.png)	

### Add Squid Proxy (Ubuntu Example)
```
	sudo apt-get -y install squid3
	
```


### Add these lines to the Squid Proxy Config
```
	vi /etc/squid3/squid.conf

```

```
	# Add this at the end of the acl part of the file around line 920 of conf file, you can tune this to be more secure as needed.


	# Start squid addition here, add your VPSA IP
	acl vpsa src <VPSA IP>/32

	acl outbound dstdom_regex .*

	#https_access allow vpsa outbound
	http_access allow vpsa outbound
```


### Restart Squid Service

```
	# Restart Squid
	service squid3 restart
```



### Testing
You can use the EICAR Standard Anti-Virus Test File as described here: https://en.wikipedia.org/wiki/EICAR_test_file
or drop the following EICAR string in a test file.  

```
X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
```

During an actual test, you should observe the EICAR file move from the scan directory to the quarantine directory along with log output indicating the test virus was discovered.





### Support

Please contact Zadara Support with any questions regarding this container.
