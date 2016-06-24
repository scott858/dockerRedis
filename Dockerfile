FROM ubuntu:16.04

#use bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN cd /home

RUN apt-get update
RUN apt-get install -y software-properties-common python-software-properties wget
RUN apt-get install -y sudo
RUN apt-get install -y vim iproute arp-scan lsof


# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r redis && useradd -r -g redis redis

RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		wget \
	&& rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

ENV REDIS_VERSION 3.2.1
ENV REDIS_DOWNLOAD_URL http://download.redis.io/redis-stable.tar.gz

# for redis-sentinel see: http://redis.io/topics/sentinel
RUN mkdir /etc/redis 
RUN mkdir /var/redis 
RUN mkdir /var/redis/7379
RUN mkdir /var/log/redis 
COPY 7379.conf /etc/redis/7379.conf
COPY redis_7379 /etc/init.d/redis_7379

RUN buildDeps='gcc libc6-dev make' \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& wget "$REDIS_DOWNLOAD_URL" \
	&& tar -xzf redis-stable.tar.gz \
	&& rm redis-stable.tar.gz \
	&& cd redis-stable \
	&& make \
	&& make install \
	&& update-rc.d redis_7379 defaults \
	&& apt-get purge -y --auto-remove $buildDeps

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir /data && chown redis:redis /data
VOLUME /data
WORKDIR /data

EXPOSE 7379
ENTRYPOINT ["/docker-entrypoint.sh"]
