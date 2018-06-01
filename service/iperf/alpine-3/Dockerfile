FROM zadara/ssh:alpine
ENV SSH_SERVER="disabled"

LABEL description="iperf3 container"

RUN apk --no-cache add iperf3

EXPOSE 5001/tcp
EXPOSE 5001/udp

ENV IPERF_PORT=5001

COPY ./start-iperf.sh /start/001-iperf.sh
