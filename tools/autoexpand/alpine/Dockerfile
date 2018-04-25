FROM zadara/service-cron:alpine
ENV SSH_SERVER="disabled"

LABEL description="autoexpand tool for increasing volume capacity dynamically of a VPSA"

RUN apk --no-cache add jq

ENV VPSA_ACCESS_KEY=""

COPY ./scripts /scripts
COPY ./runonce-storeenv.sh /runonce/000-storeenv.sh
COPY ./runonce-setCron.sh /runonce/001-setCron.sh
