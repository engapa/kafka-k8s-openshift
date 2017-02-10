#!/bin/bash -e

function download_kafka_release () {

  KAFKA_VERSION=${1:-${KAFKA_VERSION}}
  SCALA_VERSION=${2:-${SCALA_VERSION}}
  KAFKA_HOME=${3:-${KAFKA_HOME}}

  if [[ -z $KAFKA_VERSION || -z $SCALA_VERSION || -z $KAFKA_HOME ]]; then
    echo 'KAFKA_VERSION, SCALA_VERSION and KAFKA_HOME are required values.' && exit 1;
  fi

  URL_PREFIX="https://dist.apache.org/repos/dist/release/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}"

  wget -q -O /tmp/kafka.tgz "${URL_PREFIX}.tgz"
  wget -q -O /tmp/kafka.asc "${URL_PREFIX}.tgz.asc"

  wget -q -O /tmp/KEYS https://kafka.apache.org/KEYS
  gpg -q --import /tmp/KEYS

  gpg -q --batch --verify /tmp/kafka.asc /tmp/kafka.tgz
  tar -xzf /tmp/kafka.tgz --strip-components 1 -C $KAFKA_HOME

  rm -rf /tmp/kafka.{asc,tgz} \
         /tmp/KEYS
  rm -rf $KAFKA_HOME/{NOTICE,LICENSE} \
         $KAFKA_HOME/site-docs \
         $KAFKA_HOME/bin/windows

}

function download_kafka_utils() {

  wget -q -O ${KAFKA_HOME}/bin/kafka_common_functions.sh https://raw.githubusercontent.com/engapa/utils-docker/master/common-functions.sh

}

download_kafka_release "$@" && download_kafka_utils