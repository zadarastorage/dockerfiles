# iozone

Dockerized IOzone app built on top of official Ubuntu images.

Image specific:

- [iozone](http://www.iozone.org)

## Run example

```bash


$ ssh -p 92xx YOUR_VPSA_IP

$ cd /mnt/your_mapped_volume

# Sequential Write, 64K requests, 32 threads:

iozone -I -t 32 -M -O -r 64k -s 500m -+u -w -i 0

# Sequential Read, 64K requests, 32 threads:

iozone -I -t 32 -M -O -r 64k -s 500m -+u -w -i 1

# Random Read/Write, 4K requests, 32 threads:

iozone -I -t 32 -M -O -r 4k -s 500m -+u -w -i 2

```

