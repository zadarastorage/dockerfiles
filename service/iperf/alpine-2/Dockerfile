FROM zadara/ssh:alpine
ENV SSH_SERVER="disabled"

LABEL description="iperf container"

RUN apk --no-cache add iperf

EXPOSE 5001

ENV IPERF_PORT=5001

COPY ./start-iperf.sh /start/001-iperf.sh
