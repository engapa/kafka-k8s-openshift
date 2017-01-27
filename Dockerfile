FROM java:8-jre-alpine

MAINTAINER Enrique Garcia <engapa@gmail.com>

ENV KAFKA_REPLICAS=1 \
    KAFKA_VERSION="0.10.1.0" \
    SCALA_VERSION="2.11" \
    KAFKA_HOME=/srv/kafka \
    PATH=${PATH}:${KAFKA_HOME}/bin \
    SERVER_LOG_DIRS=/kafka/kafka-logs \
    KAFKA_ZK_LOCAL=true \
    ZK_dataDir="/kafka/zookeeper/data" \
    ZK_dataLogDir="/kafka/zookeeper/log"


VOLUME ["/kafka"]

ADD kafka_download.sh kafka_setup.sh kafka_start.sh kafka_ok.sh /

RUN set -x \
    && chmod a+x /kafka_* \
    && apk add --update --no-cache bash wget curl jq coreutils

RUN set -x \
    && ./kafka_download.sh \
    && rm -rf ${KAFKA_HOME}/NOTICE \
    && rm -rf ${KAFKA_HOME}/LICENSE \
    && rm -rf ${KAFKA_HOME}/site-docs \
    && rm -rf ${KAFKA_HOME}/bin/windows \
    && rm -rf /kafka_download.sh \
    && mv /kafka_* ${KAFKA_HOME}/bin

WORKDIR ${KAFKA_HOME}

ENTRYPOINT ["bin/kafka_setup.sh"]