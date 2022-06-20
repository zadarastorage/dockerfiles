# Build base
FROM lsiobase/ubuntu:focal as s6-base
LABEL maintainer="Zadara Storage <support@zadarastorage.com>" \
      vendor="Zadara Storage"
COPY s6-base/ /

# Build ssh
FROM s6-base as s6-ssh

ENV SSH_USER="root" \
    SSH_PASSWORD="zadara"

EXPOSE 22

RUN \
    apt-get update && \
    apt-get install -y \
      openssh-server \
      acl attr \
      iproute2 \
      rsync curl wget \
      screen less && \
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo 'UseDNS no' >> /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    rm -f /etc/cont-init.d/10-adduser && \
    rm -f /etc/ssh/ssh_host_* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY s6-ssh /

# Build cron
FROM s6-ssh as s6-cron

RUN \
    apt-get update && \
    apt-get install -y \
      cron logrotate && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY s6-cron /

# Build clamav
FROM s6-cron

ENV SSH_SERVICE="disabled" \
    TZ="UTC"

RUN \
    apt-get update && \
    apt-get install -y \
      clamav-daemon clamav-freshclam curl jq parallel && \
    sed -i 's/ReceiveTimeout.*/ReceiveTimeout 60/' /etc/clamav/freshclam.conf && \
    freshclam && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY s6 /
COPY app /app
