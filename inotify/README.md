# inotify

inotify is an efficient method of watching for filesystem events in Linux.  It uses integrations into the Linux kernel and glibc to see these events.

## Use Case

This Dockerfile can be adapted by an administrator to fire ad-hoc events when a file change is observed in the specified "watched" volume.  In this example, we echo that a new file has been observed in the console output.  However, obviously, this can be adapted to do more useful things, like:

* Add an event to a pub-sub queue like RabbitMQ or Redis
* Transcode an input raw video source to an encoded output or outputs of your choosing
* Move or copy a file to a different destination directory
* And more...

## SSH

This Dockerfile also adds SSH daemon support in the event the administrator wishes to login to the container remotely to do any troubleshooting.  This is optional and can be disabled by commenting out the appropriate sections in the Dockerfile.  **If you do choose to retain SSH access, please change the root password ASAP.**

## Creating The Container

Some screeenshots are included below to explain how to create this container with all required settings on Zadara Container Services.

### Ports

If you wish to access this container via SSH, specify that port 22 should be accessible:

![](https://github.com/zadarastorage/dockerfiles/blob/master/inotify/screenshots/inotify_zcs_port.png)

### Volumes

You need to specify which Zadara NAS Share will be mounted in the container and where.  In this case, we will mount the "inotify-watch-volume" NAS Share to "/inotify-watch-volume" in the container:

![](https://github.com/zadarastorage/dockerfiles/blob/master/inotify/screenshots/inotify_zcs_volume.png)

### Arguments

The arguments you specify will be fed to the entry point script, in this case "/start.sh".  The example only needs one argument - the path to the watched directory, in this case "/inotify-watch-volume":

![](https://github.com/zadarastorage/dockerfiles/blob/master/inotify/screenshots/inotify_zcs_args.png)

### Entry Point

Finally, the ZCS engine needs to know what script to run when the container launches.  Specify to run "/start.sh" as specified in the Dockerfile:

![](https://github.com/zadarastorage/dockerfiles/blob/master/inotify/screenshots/inotify_zcs_entry.png)

## Support

Please contact Zadara Support with any questions regarding this container.