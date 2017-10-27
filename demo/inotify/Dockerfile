# This demo Docker container will watch a directory specified as an argument
# to the ZCS container with inotifywait, and echo the filename to standard
# output.  This is obviously not of much use, but it can easily be adapted
# to a more specific workload.

FROM ubuntu:trusty
MAINTAINER Jeremy Brown "https://github.com/jwbrown77"

# SSH is optional, but it's included here to make experimentation easier.  To
# perform more useful functions, install the required program(s) you need 
RUN apt-get update && apt-get install -y openssh-server inotify-tools

# REMEMBER TO CHANGE ROOT PASSWORD AFTER LAUNCH
RUN echo 'root:zadara' | chpasswd

# Remove if you don't need SSH
RUN mkdir /var/run/sshd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'UseDNS no' >> /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
EXPOSE 22

ADD ./start.sh /start.sh

CMD /start.sh
