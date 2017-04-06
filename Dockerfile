FROM java:8-jre-alpine

MAINTAINER Enrique Garcia <engapa@gmail.com>

ARG KAFKA_HOME=/opt/kafka
ARG KAFKA_USER=kafka
ARG KAFKA_GROUP=kafka
ARG KAFKA_VERSION="0.10.1.1"
ARG SCALA_VERSION="2.12"

ENV KAFKA_HOME=${KAFKA_HOME} \
    KAFKA_VERSION=${KAFKA_VERSION} \
    SCALA_VERSION=${SCALA_VERSION} \
    KAFKA_ZK_LOCAL=true \
    KAFKA_REPLICAS=1 \
    SERVER_port=9092

# Required packages
RUN set -x \
    && apk add --update --no-cache \
       bash sudo tar gnupg openssl ca-certificates

# Download kafka distribution under KAFKA_HOME directory
ADD kafka_download.sh /tmp/

RUN set -x \
    && mkdir -p $KAFKA_HOME \
    && chmod a+x /tmp/kafka_download.sh \
    && /tmp/kafka_download.sh \
    && rm -rf /tmp/kafka_download.sh \
    && apk del gnupg

# Add custom scripts and configure user
ADD kafka_setup.sh kafka_server.sh kafka_env.sh $KAFKA_HOME/bin/

RUN set -x \
    && chmod a+x $KAFKA_HOME/bin/kafka_*.sh \
    && addgroup $KAFKA_GROUP \
    && addgroup sudo \
    && adduser -h $KAFKA_HOME -g "Kafka user" -s /sbin/nologin -D -G $KAFKA_GROUP -G sudo $KAFKA_USER \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && chown -R $KAFKA_USER:$KAFKA_GROUP $KAFKA_HOME \
    && ln -s $KAFKA_HOME/bin/kafka_*.sh /usr/bin

USER $KAFKA_USER
WORKDIR $KAFKA_HOME

EXPOSE $SERVER_port

ENTRYPOINT ["kafka_env.sh"]