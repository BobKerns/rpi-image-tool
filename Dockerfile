# syntax = docker/dockerfile:1.2

FROM ubuntu as kpartx
ARG TAG=pi:latest
RUN apt update \
    && apt-get -y install kpartx kmod multipath-tools errno \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install emacs \
    && mkdir -p /data /data/build/root /data/build/root/boot /data/bin /data/local/bin
ENV PATH "/data/local/bin:/data/bin:${PATH}"
COPY bin/ /data/bin/
WORKDIR /data/local
ENTRYPOINT ["/data/bin/inc/start"]
