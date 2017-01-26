#!/bin/bash -e

# Download
mirror=$(curl --stderr /dev/null https://www.apache.org/dyn/closer.cgi\?as_json\=1 | jq -r '.preferred')
url="${mirror}kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
wget -q "${url}" -O "/tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /srv
rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
ln -s /srv/kafka_${SCALA_VERSION}-${KAFKA_VERSION} $KAFKA_HOME