# GCP gusutil     

Dockerized Google Cloud Platform gsutil built on Alpine Zadara SSHD

## Installed Tools

* gsutil
* sshd

## SSH Access

```
root@<docker-image-ip>
```

Password is zadara. Change upon first login.

## .boto

Map your .boto file to /root or run

```
gsutil config
```
Follow instructions and steps layed out in the config script output.
