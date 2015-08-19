# ZCS Dockerfiles

![](https://pbs.twimg.com/media/CIMSwtYWsAQ7PTg.jpg)

Each folder contains a Dockerfile and script(s) configured for a
specific application which we run and tested for the Zadara
Container Services (ZCS).

## Quick Start

Some of the applications are preconfigured and available in the Docker
public repository. We suggest that you download:

```
zadara/ssh
```

as your first Docker image to deploy on your VPSA. This image will
allow you to ssh into the container from your private network to the
VPSA. If you mounted your volumes onto this container you will be
able to access the data with R/W or R/O restrictions.

## Building Your Docker Apps

ZCS is an embedded platform so you will not be able to attach to your
running container.  This is why we suggest using:

```
ssh/Dockerfile
ssh/start.sh
```

found in this repository as a baseline for future development or to
include the specific build commands and sshd service startup prior
to running your app.

This will allow you to access your container via ssh. Please remember
to change the default password once you log into the container.

### Public Apps

If you are planning to deploy your containers via the Docker repository,
you will need a git hub or bit bucket account and a Docker account. You 
then you can use the Docker repository as a reference for installing
images for ZCS use.

Note that not all images in the Docker repository will work out of the
box on the ZCS platform. Usually it requires a minor change before 
it can work. Please contact us if you need assistance do this.

### Private Apps

Creating private apps is the quickest way to test your container. This
involves building and running a container then saving the container
file system as a tar file to VPSA volume accessible to your Docker build machine.

If you don't have a docker build machine, create an Ubuntu instance or
use an existing one and install docker:

```
curl -sSL https://get.docker.com/ | sh
```

After you have Docker installed, build an image. For starters, please
consider using our ssh/Dockerfile after you clone this repo.

```
cd ssh
docker build -t namespace/ssh .
```

The tag "-t" can be any unique identifier, but the convention is namepace/app.
When we build this, we would use -t zadara/ssh.

After you build the app, run it interactively

```
docker run -it -p 9222:22 namespace/ssh
```

Exit interactive mode by typing Ctrl-p and then Ctrl-q. This will bring you back
to the command line of your server.

You can get the IP address of the running container first by obtaining the
docker container id using the ps and inspect commands.

```
docker ps
docker inspect container_id | grep IP
```

The docker ps command will return the 12-hexadecimal container id and then use that value to 
inspect the contents of the container. All we need is the IP to ssh into it.

```
ssh -p 9222 root@192.168.10.22
```

Once you're logged in, change the password from "zadara" to something else. Exit the
ssh session and then stop the container.

```
docker stop container_id
```

The last step is to create a file system tar of the container that was just running
to a volume on the VPSA. It's a good practice to create a new volume separate from
your production date for this. Simply create a 100GB NAS share and attach your Docker
build machine to it. 

I usually create a dockerimages volume and mount this volume as /mnt/dockerimages.

Issue the export command:

```
mkdir /mnt/dockerimages/namespace
docker export container_id > /mnt/dockerimages/namespace/ssh.tar
```

To create an ZCS image from the VPSA GUI, you would then select your dockerimages
volume and the namespace/ssh.tar file.  After which you would run a container
using this image.
