FROM openjdk:8-jre-alpine

MAINTAINER Enrique Garcia <engapa@gmail.com>

ARG KAFKA_HOME=/opt/kafka
ARG KAFKA_USER=kafka
ARG KAFKA_GROUP=kafka
ARG KAFKA_VERSION="2.5.0"
ARG SCALA_VERSION="2.13"

ENV KAFKA_HOME=${KAFKA_HOME} \
    KAFKA_VERSION=${KAFKA_VERSION} \
    SCALA_VERSION=${SCALA_VERSION} \
    KAFKA_ZK_LOCAL=true \
    KAFKA_REPLICAS=1 \
    KAFKA_USER=$KAFKA_USER \
    KAFKA_GROUP=$KAFKA_GROUP \
    KAFKA_DATA_DIR=$KAFKA_HOME/data \
    SERVER_port=9092 \
    ZK_clientPort=2181

# Required packages
RUN apk add --update --no-cache \
       bash tar gnupg openssl ca-certificates sudo

# Download kafka distribution under KAFKA_HOME directory
ADD kafka_download.sh /tmp/

RUN mkdir -p $KAFKA_HOME \
    && chmod a+x /tmp/kafka_download.sh

RUN /tmp/kafka_download.sh

RUN rm -rf /tmp/kafka_download.sh \
    && apk del gnupg

# Add custom scripts and configure user
ADD kafka_*.sh $KAFKA_HOME/bin/

RUN addgroup -S -g 1001 $KAFKA_GROUP \
    && adduser -h $KAFKA_HOME -g "Kafka user" -u 1001 -D -S -G $KAFKA_GROUP $KAFKA_USER \
    && chown -R $KAFKA_USER:$KAFKA_GROUP $KAFKA_HOME \
    && chmod a+x $KAFKA_HOME/bin/kafka_*.sh \
    && chmod -R a+w $KAFKA_HOME \
    && ln -s $KAFKA_HOME/bin/kafka_*.sh /usr/bin \
    && echo "${KAFKA_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $KAFKA_USER
WORKDIR $KAFKA_HOME/bin/

EXPOSE $ZK_port $SERVER_port

HEALTHCHECK --interval=10s --retries=10 CMD "kafka_server_status.sh"

CMD kafka_server.sh start
