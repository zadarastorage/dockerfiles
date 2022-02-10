# ClamAV


ClamAV is a mature open source AntiVirus solution for Linux.  This container periodically walks the filesystem to monitor changes in file shares, then feed the list of files to the ClamAV service for virus scanning.  Infected files are sent to quarantine and events are logged.  

## Use Case

This Dockerfile can be adapted by an administrator to scan directories in various shares as they are updated and quarantine files without affecting performance.


## Quick Start
#### Requirements
This container currently requires a minimum VPSA App Engine size of "06", the container will fail to start if any smaller.  
It is recommended to create a dedicated VPSA User to generate an API Access Key for this specific purpose.  
Image is available on the Docker Hub at https://hub.docker.com/r/zadara/clamav-cron  

#### Configuration
This container is configured through Environment Variables (Example of expected value type/formats, yours will be different):
* Required
  * `SCAN_PATH`="/export/volume-a /export/volume-b"
    * Space-delimited list of paths inside the container to scan
  * `LOG_PATH`="/export/clamav_log"
    * The path for clamav to store it's logs and scan queue
* Optional
  * `SCAN_FILE`="/export/clamav_log/volumes.txt"
	  * Overrides SCAN_PATH
	  * Text file containing new-line delimited list of volumes, incase desired volume strings are too long for use as an environment variable
  * `QUAR_PATH`="/export/clamav_quarantine"
    * The path for clamav to move infected objects to, if undefined, file will not be moved
  * `VPSA_ACCESSKEY`="4CDMR0NR9U8TJHZGWM2S-3827"
    * A VPSA User's API key
    * Is used to open a support ticket to notify the user when any infected files are detected
    * It is best to create a dedicated user for this purpose as API Keys are cleared alongside password resets
  * `ENABLE_SSH`="anything"
    * Enable's built-in SSH server on port 22, default credentials are `root:zadara`, this is intended for initial debugging and should not be used long-term. **Do make sure to change the password on first login.**
    * `Port 22` also needs to be exposed on a port greater than 9216 when launching the image on a VPSA.
  * `PROXY_SERVER`="10.1.1.100"
  * `PROXY_PORT`="3128"
    * Externally available HTTP proxy for updating virus definitions if not using Public IP feature or if the VPSA's Frontend network does not provide a path to the public internet
  * `DEF_UPD_FREQ`="24"
    * The frequency in which to download the virus definitions updates per day.
    * This default is 24 times a day, or every hour.
  * `FIND_CRON`="`0 * * * *`"
	  * Default is hourly at a randomly selected minute offset, this allows explicit control if necessary
	  * Attempts to scan the specified volumes for any new or modified files since the previous scan
  * `AV_CRON`="`30 * * * *`"
	  * Default is hourly at a randomly selected minute offset, this allows explicit control if necessary
	  * Performs AV scans of new/modified files reported as changed by the "FIND_CRON" process




## Creating The Container

Some screenshots are included below to explain how to create this container with all required settings on Zadara Container Services.

### Ports

If you wish to access this container via SSH, specify that port 22 should be accessible:

![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/application/clamav/ubuntu-inotify/screenshots/add_port.png)

### Volumes

You need to specify which Zadara NAS Share volume(s) will be mounted in the container.  There can be a single or multiple shares mounted for scanning, logging and quarantine.  In this case we are just using 'nas-1' mounted as '/mnt/ex_scan_vol' and 'nas-2' mounted as '/mnt/ex_log_vol':

![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/application/clamav/ubuntu-inotify/screenshots/add_vol.png)

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

![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/application/clamav/ubuntu-inotify/screenshots/add_env_variables.png)

### Entry Point

Not required

## SQUID PROXY (optional)

ClamAV docker container -> squid proxy ec2 instance -> Internet

The Squid proxy is used to allow for virus definitions to be retrieved from the internet by the docker container.  Currently our container service does not have direct internet access however since the containers can communicate with the VPC attached to your VPSA, a proxy to the internet can be setup on an EC2 instance. 


The instance will not need a lot of local storage, so the default amount (8GB as of this writing) should be ok.

## AWS
Make sure to allow 3128 from IP Range of the VPSA on the EC2 instance security group.
	
![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/application/clamav/ubuntu-inotify/screenshots/aws_sec_group.png)	

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
