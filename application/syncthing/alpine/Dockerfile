FROM zadara/ssh:alpine
ENV SSH_SERVER="disabled"

LABEL description="Syncthing container"

RUN apk --no-cache add syncthing

EXPOSE 8384 22000 21027/udp

ENV SYNCTHING_PORT=8384 \
    SYNCTHING_DATA_DIR="/export" \
    SYNCTHING_CONF_DIR="/conf" \
    STNOUPGRADE=1 \
    STNODEFAULTFOLDER=1

COPY ./start-syncthing.sh /start/001-syncthing.sh
