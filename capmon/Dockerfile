FROM ubuntu
FROM library/influxdb
FROM grafana/grafana

LABEL      maintainer="Zadara Storage <support@zadarastorage.com>"
LABEL      Description="VPSA Monitor" Vendor="Zadarastorage"
LABEL      Version="0.26"

ENV        GF_SERVER_ROOT_URL http://localhosti
ENV        GF_SECURITY_ADMIN_PASSWORD zadara

WORKDIR /zadara
COPY getcap.py /zadara
COPY startup.sh /zadara

RUN echo 'Create Zadara Volume Monitoring generic Container'
RUN apt-get update
RUN apt-get install -y curl

EXPOSE 3000 8083 8086

ENTRYPOINT ["/bin/bash", "-c", "/zadara/start.sh"]
