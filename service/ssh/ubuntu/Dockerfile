FROM ubuntu:trusty

LABEL maintainer="Zadara Storage <support@zadarastorage.com>" \
      vendor="Zadara Storage"

LABEL description="Simple SSH Server preloaded with some commonly-used packages"

# Install and configure SSH
RUN apt-get update && \
    apt-get install -y openssh-server acl attr rsync curl wget screen && \
    mkdir /var/run/sshd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
#    echo 'root:zadara' | chpasswd && \
    echo 'UseDNS no' >> /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    apt-get clean

EXPOSE 22

ENV SSH_SERVER="enabled" \
    SSH_USER="root" \
    SSH_PASSWORD="zadara"

COPY ./start.sh /start.sh
COPY ./start-ssh.sh /start/000-ssh.sh

CMD ["/start.sh"]
