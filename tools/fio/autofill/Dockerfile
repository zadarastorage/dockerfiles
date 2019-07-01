FROM alpine:3.8

# Install apk packages
RUN apk --update add bash procps htop iftop --no-cache

RUN apk --no-cache add \
    	make \
	alpine-sdk \
	zlib-dev \
	libaio-dev \
	linux-headers \
	coreutils \
	libaio && \
    git clone https://github.com/axboe/fio && \
    cd fio && \
    ./configure && \
    make -j`nproc` && \
    make install && \
    cd .. && \
    rm -rf fio && \
    apk --no-cache del \
    	make \
	alpine-sdk \
	zlib-dev \
	libaio-dev \
	linux-headers \
	coreutils

COPY Dockerfile /app/
COPY start.sh /app/
COPY fio-fill.job /app/
RUN chmod +x /app/start.sh

CMD bash /app/start.sh
