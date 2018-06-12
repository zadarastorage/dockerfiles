FROM zadara/service-cron:alpine
ENV SSH_SERVER="disabled"

LABEL description="zprivnotification for monitoring VPSA logs and generating a ticket on escalated privileged access events."

RUN apk --no-cache add jq

ENV VPSA_ACCESS_KEY="" \
    GENERATE_TICKET="enabled"

COPY ./scripts /scripts
COPY ./runonce-storeenv.sh /runonce/000-storeenv.sh
COPY ./runonce-clearlocks.sh /runone/001-clearlocks.sh
COPY ./runonce-setCron.sh /runonce/002-setCron.sh
