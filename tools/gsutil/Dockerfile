#
# Build for GCP gsutil
#

FROM zadara/ssh 

MAINTAINER Howard Young "https://github.com/threadx"

RUN apk update

# From https://github.com/camilb/docker-gsutil

RUN apk add  \
    python \
    py-pip \
    py-cffi \
    py-cryptography \
  && pip install --upgrade pip \
  && apk add --virtual build-deps \
    gcc \
    libffi-dev \
    python-dev \
    linux-headers \
    musl-dev \
    openssl-dev \
  && pip install gsutil \
  && apk del build-deps \
  && rm -rf /var/cache/apk/*
