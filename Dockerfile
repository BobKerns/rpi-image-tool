# syntax = docker/dockerfile:1.3

FROM ubuntu as kpartx
ARG TAG=pi:latest

# This Dockerfile is carefully arranged for quick rebuilding.
# 1) Less-frequently changed layers are placed first
# 2) Packages downloaded by apt-get are cached
# 3) If you are developing/debugging subcommand scripts, running in the
#    root directory of the project will pick up changes in the bin/ subdirectory
#    without needing to rebuild the Docker container, because we include
#    /data/local/bin in the path, and our standard rpi-image-tool script
#    bind-mounts the current directory on /data/local.


# Arrange to cache and not delete the downloaded packages.
# This goes first, because it should be in any apt-caching build,
# so can be widely reused.
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true"; APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-cache \
    && apt-get update \
    && ((echo 'y'; echo 'y') | unminimize)

# Install Emacs first, because it takes a long time to load and we can cache this
# allowing the list of additional packages to be changed without having to redo all
# the work.
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    DEBIAN_FRONTEND=noninteractive apt-get -y install emacs

# Our directory structure should be fairly stable, but no need to reload emacs if it does.
# So we put creating the directories, setting PATH, and the WORKDIR in the next 3 layers.
RUN mkdir -p /data /data/build/root /data/build/root/boot /data/bin /data/local/bin /data/mnt
ENV PATH "/data/local/bin:/data/bin:${PATH}"
WORKDIR /data/local

# The main list of packages to be installed.

RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt-get -y install git kpartx kmod multipath-tools parted errno dosfstools

# Our script data is the most likely to change, and quick to load.
COPY bin/ /data/bin/

VOLUME [ "/image" ]

# This is the script that runs when we invoke the container. It sets up the context
# (mounts, environment variables) for the subcommand scripts, and runs them.
ENTRYPOINT ["/data/bin/inc/start"]
