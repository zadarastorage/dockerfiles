#
# ZCS Build for Zadara Aging Utility
#

FROM       ubuntu

MAINTAINER Howard Young "https://github.com/threadx"

RUN apt-get update --fix-missing

RUN apt-get install -y g++
RUN apt-get install -y make


WORKDIR /usr/bin
ADD ./zage.c /usr/bin/zage.c
ADD ./Makefile /usr/bin/Makefile

RUN make

# vi just doesn't cut it anymore

RUN apt-get install -y vim

#
# Add ssh since ZCS doesn't support -it
#

RUN apt-get update && apt-get install -y openssh-server

RUN mkdir /var/run/sshd
RUN echo 'root:zadara' | chpasswd

RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'UseDNS no' >> /etc/ssh/sshd_config

RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ADD ./start.sh /start.sh

EXPOSE 22



CMD /start.sh
