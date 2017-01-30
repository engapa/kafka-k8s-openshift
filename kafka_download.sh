#!/bin/bash -e

function download_kafka_release () {

  KAFKA_VERSION=${1:-${KAFKA_VERSION}}
  SCALA_VERSION=${2:-${SCALA_VERSION}}
  KAFKA_HOME=${3:-${KAFKA_HOME}}

  if [[ -z $KAFKA_VERSION || -z $SCALA_VERSION || -z $KAFKA_HOME ]]; then
    echo 'KAFKA_VERSION, SCALA_VERSION and KAFKA_HOME are required values.' && exit 1;
  fi

  wget -q -O /tmp/KEYS https://kafka.apache.org/KEYS
  gpg -q --import /tmp/KEYS
  wget -q -O /tmp/kafka.asc \
    "https://dist.apache.org/repos/dist/release/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz.asc"

  mirror=$(curl --stderr /dev/null https://www.apache.org/dyn/closer.cgi\?as_json\=1 | jq -r '.preferred')
  url="${mirror}kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
  wget -q -O "/tmp/kafka.tgz" "${url}"

  gpg -q --verify /tmp/kafka.asc /tmp/kafka.tgz
  tar -xzf /tmp/kafka.tgz --strip-components 1 -C $KAFKA_HOME

  rm -rf /tmp/kafka.{asc,tgz}
  rm -rf /tmp/KEYS
  rm -rf $KAFKA_HOME/NOTICE
  rm -rf $KAFKA_HOME/LICENSE
  rm -rf $KAFKA_HOME/site-docs
  rm -rf $KAFKA_HOME/bin/windows

}

function download_kafka_utils() {

  wget -q -O ${KAFKA_HOME}/bin/kafka_common_functions.sh https://raw.githubusercontent.com/engapa/utils-docker/master/common-functions.sh

}

download_kafka_release "$@" && download_kafka_utils