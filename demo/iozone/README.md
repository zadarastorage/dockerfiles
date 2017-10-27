# ZCS iozone
![](https://raw.githubusercontent.com/zadarastorage/dockerfiles/master/iozone/assets/iozone-re-read.jpg)

Dockerized IOzone app built on top of official Ubuntu images desiged to run in Zadara's ZCS

Image specific:

- [iozone](http://www.iozone.org)

## Building

The best way to evaluate your VPSA is to build iozone as a [private app](https://github.com/zadarastorage/dockerfiles#private-apps) from a Linux instance connected to your VPSA. Run the container once from Linux to test your network and NFS performance and then on the VPSA virtual controller to see the performance difference.

## Run example

```bash

$ ssh -p 92xx root@YOUR_VPSA_IP

# The passwd for the container is zadara
# Change the passwd once you log into it and then stop it afterwards to prevent access 
# to your_mapped_volume from this container

$ cd /mnt/your_mapped_volume

# Sequential Write, 64K requests, 32 threads:

iozone -I -t 32 -M -O -r 64k -s 500m -+u -w -i 0

# Sequential Read, 64K requests, 32 threads:

iozone -I -t 32 -M -O -r 64k -s 500m -+u -w -i 1

# Random Read/Write, 4K requests, 32 threads:

iozone -I -t 32 -M -O -r 4k -s 500m -+u -w -i 2

```

