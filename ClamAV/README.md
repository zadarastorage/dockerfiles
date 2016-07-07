# ClamAV

ClamAV is a mature open source AntiVirus solution for Linux.  This continer utilizes iNotify to monitor changes in file shares which then feed the files to the ClamAV service for virus scanning.  Infected files are sent to quarantine and events are logged.  

A list of virus definitions can be installed at build time however to keep definitions current it is best add a proxy to allow freshclam to update these regularly.


## Use Case

This Dockerfile can be adapted by an administrator to scan directories in various shares as they are updated and quarantine files without affecting performance.


## SSH

This Dockerfile also adds SSH daemon support in the event the administrator wishes to login to the container remotely to do any troubleshooting.  This is optional and can be disabled by commenting out the appropriate sections in the Dockerfile.  **If you do choose to retain SSH access, please change the root password ASAP.**

## Creating The Container

Some screeenshots are included below to explain how to create this container with all required settings on Zadara Container Services.

### Ports

If you wish to access this container via SSH, specify that port 22 should be accessible:



### Volumes

You need to specify which Zadara NAS Share will be mounted in the container and where.  You can have single or multiple shares mounted for scanning, logging and quarantine.  In this case we are just using 'nas-1' mounted as '/mnt/ex_scan_vol' and 'nas-2' mounted as '/mnt/ex_log_vol':


### Environment Variables

These variables allow you to specify your proxy, scan, quarantine and log directories: 

(optional)
PROXY_SERVER - IP Address to the proxy server allowing access to download virus definition updates
PROXY_PORT - Port number to the proxy server allowing access to download virus definition updates
DEF_UPD_FREQ - The frequency in which to download the virus definition udpates

(required)
SCAN_PATH - The path(s) to the added volume in which to scan.  Multiple paths are simply spearated by a space.
QUAR_PATH - The path to the added volume in which infected files are moved to.
LOG_PATH - The path for log output.  'clamav-clamd.log', 'clamav-freshclamd.log' and 'clamav-scans.log' are sent to this directory.




### Entry Point

Not required, the container will start automatically using.





##SQUID PROXY (not requred for testing)

clamav docker container -> squid proxy ec2 instance -> Internet

The Squid proxy is uesd to allow for virus definitions to be retrieved from the internet to the docker container.  Currently our container service does not have internet access for security purposes however since the continers can communicate with the VPC attached to your VPSA, a proxy to the internet can be setup on an EC2 instance. 

	The proxy IP and port can be configured in the environmental variables in the container. (PROXY_SERVER,PROXY_PORT)


	The EC2 instance running the proxy does not require many resources


- AWS
	Make sure to allow 3128 from IP Range of the VPSA


- Squid Setup (on Ubuntu)	

	sudo apt-get -y install squid3
	/etc/squid3/squid.conf

	(add this at the end of the acl part of the file around line 920 of conf file, you can tune this to be secure as needed.)


	# Start squid addition here, add your VPSA IP
	acl vpsa src <VPSA IP>/32

	acl outbound dstdom_regex .*

	#https_access allow vpsa outbound
	http_access allow vpsa outbound

	# Restart Squid
	service squid3 restart



## Support

Please contact Zadara Support with any questions regarding this container.	

