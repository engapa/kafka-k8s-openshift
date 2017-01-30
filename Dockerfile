FROM java:8-jre-alpine

MAINTAINER Enrique Garcia <engapa@gmail.com>

ARG KAFKA_HOME=/opt/kafka
ARG KAFKA_USER=kafka
ARG KAFKA_GROUP=kafka
ARG KAFKA_VERSION="0.10.1.1"
ARG SCALA_VERSION="2.12"

# Caution: Environment variable names are case sensitive (ZK_)
ENV KAFKA_HOME=${KAFKA_HOME}              \
    KAFKA_VERSION=${KAFKA_VERSION}        \
    SCALA_VERSION=${SCALA_VERSION}        \
    KAFKA_REPLICAS=1

# Required packages
RUN set -x                                                           \
    && apk add --update --no-cache                                   \
       bash tar wget curl jq coreutils gnupg openssl ca-certificates

# Download kafka distribution under KAFKA_HOME directory
ADD kafka_download.sh /tmp/

RUN set -x                              \
    && mkdir -p $KAFKA_HOME             \
    && chmod a+x /tmp/kafka_download.sh \
    && /tmp/kafka_download.sh           \
    && rm -rf /tmp/kafka_download.sh    \
    && apk del gnupg jq wget

# Add custom scripts and configure user
ADD kafka_setup.sh kafka_server.sh $KAFKA_HOME/bin/

RUN set -x                                                                                    \
    && chmod a+x $KAFKA_HOME/bin/kafka_*.sh                                                   \
    && addgroup $KAFKA_GROUP                                                                  \
    && adduser -h $KAFKA_HOME -g "kafka user" -s /sbin/nologin -D -G $KAFKA_GROUP $KAFKA_USER \
    && chown -R $KAFKA_USER:$KAFKA_GROUP $KAFKA_HOME                                          \
    && ln -s $KAFKA_HOME/bin/kafka_*.sh /usr/bin

USER $KAFKA_USER
WORKDIR $KAFKA_HOME
