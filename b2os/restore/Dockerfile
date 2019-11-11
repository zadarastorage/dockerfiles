FROM ubuntu:bionic

LABEL maintainer="Zadara Storage <support@zadarastorage.com>" \
      vendor="Zadara Storage"

LABEL description="Advanced docker container for restoring a VPSA volume from Object Storage"

RUN apt-get update && \
    apt-get install -y ca-certificates wget libxml2 liblzo2-2 libsqlite3-0 libldap-2.4-2 libjson-c3 libjson-c-dev librtmp1 && \
    wget -P /tmp \
      http://zadarastorage-public.s3.amazonaws.com/Restore_VM/19.08/zadara-curl_7.58.0-02_amd64.deb \
      http://zadarastorage-public.s3.amazonaws.com/Restore_VM/19.08/zadara-libs3_2.0-20_amd64.deb \
      http://zadarastorage-public.s3.amazonaws.com/Restore_VM/19.08/zadara-obs_19.08-obs-2_amd64.deb \
      http://zadarastorage-public.s3.amazonaws.com/Restore_VM/19.08/zadara-protobuf-c-bionic_0.15-14_amd64.deb \
      && \
    apt-get purge -y curl && \
    apt-get install -y lsb-release initramfs-tools && \
    dpkg -i /tmp/zadara-curl_*.deb && \
    apt-get install -y libjemalloc1 google-perftools && \
    dpkg -i /tmp/zadara-libs3_*.deb /tmp/zadara-protobuf-c-bionic_*.deb /tmp/zadara-obs_*.deb && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/* /tmp/*.deb

#CMD ["sleep","60m"]
CMD ["bash","-c","zadara_obs restore --bucket=${BUCKET} --region=${AWS_REGION} --access_key=${AWS_ACCESS_KEY_ID} --secret_key=${AWS_SECRET_ACCESS_KEY} --snapshot=${SNAPSHOT_PATH} --device=${TARGET_PATH} --end_point=${ENDPOINT} --zero=${ZERO:-no}"]
