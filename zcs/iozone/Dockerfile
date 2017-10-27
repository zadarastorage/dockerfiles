FROM       ubuntu:trusty

MAINTAINER Howard Young "https://github.com/threadx"

RUN apt-get update --fix-missing

RUN apt-get -y install wget make gcc

RUN wget http://www.iozone.org/src/current/iozone3_430.tar
RUN tar xvf iozone3_430.tar 
RUN cd iozone3_430/src/current; make linux; cp iozone /usr/bin
 

RUN apt-get update && apt-get install -y openssh-server

RUN mkdir /var/run/sshd
RUN echo 'root:zadara' | chpasswd

RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'UseDNS no' >> /etc/ssh/sshd_config

RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ADD ./start.sh /start.sh

EXPOSE 22

CMD /start.sh
