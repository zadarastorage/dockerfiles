FROM ubuntu:bionic

RUN apt update

# Install apk packages
RUN apt install fio -y

COPY Dockerfile /app/
COPY start.sh /app/
COPY fio-fill.job /app/
RUN chmod +x /app/start.sh

CMD bash /app/start.sh
