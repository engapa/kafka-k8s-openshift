#!/bin/bash -e

### Default properties

function start() {

  if $KAFKA_ZK_LOCAL;then
    bin/zookeeper-server-start.sh -daemon config/zookeeper.properties
  fi

  bin/kafka-server-start.sh config/server.properties "$@"

}

start