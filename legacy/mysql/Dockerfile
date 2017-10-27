FROM ubuntu:trusty
MAINTAINER Howard Young <howard@zadarastorage.com>

EXPOSE 22
EXPOSE 3306

#
# Add ssh for ZCS command line.
# Please remember to change the passwd
#

RUN apt-get update && apt-get install -y openssh-server

RUN mkdir /var/run/sshd
RUN echo 'root:zadara' | chpasswd

RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'UseDNS no' >> /etc/ssh/sshd_config

RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd


RUN apt-get install -y mysql-server

#
# The data and the logs will be stored on /mnt/mysql  For ZCS, you can use the local Docker image 
# but the size is limited to 100G right now.
# 
# TODO: One time startup script done in real-time instead of build to accept parameters for these

RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN sed -i -e"s/^datadir\s*=\s*\/var\/lib\/mysql/datadir = \/mnt\/mysql\/data/" /etc/mysql/my.cnf
RUN sed -i -e"s/^log_error\s*=\s*\/var\/log\/mysql\/error.log/log_error = \/mnt\/mysql\/log\/error.log/" /etc/mysql/my.cnf

ADD ./start.sh /start.sh


CMD /start.sh

