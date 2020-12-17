FROM openjdk:11-jre-slim-buster

MAINTAINER Enrique Garcia <engapa@gmail.com>

ARG KAFKA_HOME=/opt/kafka
ARG KAFKA_USER=kafka
ARG KAFKA_GROUP=kafka
ARG KAFKA_VERSION="2.6.0"
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
RUN apt update && \
    apt install -y tar gnupg openssl ca-certificates wget netcat sudo

# User and group
RUN groupadd -g 1001 $KAFKA_GROUP \
    && useradd -d $KAFKA_HOME -g $KAFKA_GROUP -u 1001 -G sudo -m $KAFKA_USER\
    && echo "${KAFKA_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Download kafka distribution under KAFKA_HOME directory
ADD kafka_download.sh /tmp/kafka_download.sh
RUN chmod a+x /tmp/kafka_download.sh \
    && /tmp/kafka_download.sh

# Add custom scripts
ADD kafka_*.sh $KAFKA_HOME/bin/

# Permissions
RUN chown -R $KAFKA_USER:$KAFKA_GROUP $KAFKA_HOME \
    && chmod a+x $KAFKA_HOME/bin/kafka_*.sh \
    && chmod -R a+w $KAFKA_HOME\
    && ln -s $KAFKA_HOME/bin/kafka_*.sh /usr/bin

USER $KAFKA_USER
WORKDIR $KAFKA_HOME/bin/

EXPOSE $ZK_port $SERVER_port

HEALTHCHECK --interval=10s --retries=10 CMD "kafka_server_status.sh"

CMD kafka_server.sh start
