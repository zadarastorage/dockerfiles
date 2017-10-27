FROM alpine:3.6

LABEL maintainer="Zadara Storage <support@zadarastorage.com>" \
      vendor="Zadara Storage"

LABEL description="Simple SSH Server preloaded with some commonly-used packages"

# Install and configure SSH
RUN apk --no-cache add openssh && \
    apk --no-cache add acl attr rsync curl wget && \
    mkdir /var/run/sshd && \
    ssh-keygen -A -N '' && \
#    echo 'root:zadara' | chpasswd && \
    echo 'UseDNS no' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
EXPOSE 22

ENV SSH_SERVER="enabled" \
    SSH_USER="root" \
    SSH_PASSWORD="zadara"

COPY ./start.sh /start.sh
COPY ./start-ssh.sh /start/000-ssh.sh

CMD ["/start.sh"]
