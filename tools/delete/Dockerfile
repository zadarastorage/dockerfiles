FROM python:3.7-alpine3.8

# Install apk packages
RUN apk --update add procps htop iftop openssh bash --no-cache

# Install and setup SSH
RUN sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
  && echo "root:zadara" | chpasswd \
  && rm -rf /var/cache/apk/*

RUN sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config && \
    sed -ri 's/#HostKey \/etc\/ssh\/ssh_host_key/HostKey \/etc\/ssh\/ssh_host_key/g' /etc/ssh/sshd_config && \
    sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config && \
    sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config && \
    sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config && \
    sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config && \
    /usr/bin/ssh-keygen -A && \
    ssh-keygen -t rsa -b 4096 -f  /etc/ssh/ssh_host_key

EXPOSE 22

RUN pip install joblib --no-cache-dir

ENV PYTHONUNBUFFERED=0 \
    TERM=xterm \
    CRON=enabled \
    CRON_TIMING="0 0 * * *" \
    KEEP_ALIVE=disabled \
    SSH=disabled \
    STARTUP_RUN=enabled \
    DRY_RUN=enabled \
    CASE_SENSITIVE_PATTERNS=disabled

COPY Dockerfile /app/
COPY start.sh /app/
COPY *.py /app/

RUN chmod +x /app/start.sh

CMD bash /app/start.sh
