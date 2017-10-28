FROM zadara/ssh:alpine
ENV SSH_SERVER="disabled"

LABEL description="Minio-powered S3 service"

RUN mkdir /app && \
    wget https://dl.minio.io/server/minio/release/linux-amd64/minio -O /app/minio && \
    chmod +x /app/minio

EXPOSE 9000

# MINIO_ACCESS_KEY must be >5 length, MINIO_SECRET_KEY must be >8 length
ENV MINIO_SERVER="enabled" \
    MINIO_ACCESS_KEY="zadara" \
    MINIO_SECRET_KEY="zadarazadara" \
    MINIO_REGION="zadara_vpsa" \
    MINIO_BROWSER="on" \
    MINIO_DATA_DIR="/export" \
    MINIO_CONF_DIR="/conf" \
    VPSA_ACCESS_KEY=""

COPY ./start-minio.sh /start/001-minio.sh
