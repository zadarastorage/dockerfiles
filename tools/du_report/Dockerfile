FROM zadara/ssh:alpine
ENV SSH_SERVER="disabled"

LABEL description="Disk usage container"

RUN mkdir /app && apk update && apk add tree

ENV VPSA_ACCESS_KEY="" \
    DIRECTORY_DEPTH=2 \
    TARGET_DIRECTORY="/" \
    OUTPUT_DIRECTORY="/" \
    TREE="true" \
    TREE_OUTPUT_FORMAT="JSON" \
    CRON_STRING="* * * * *" \
    SIZES_HUMAN_READABLE="true"

COPY ./start-cron.sh /start/001_start-cron.sh
COPY ./start-du.sh /app/start-du.sh

RUN chmod +x /app/*

