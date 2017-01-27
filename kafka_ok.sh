#!/bin/bash -e

if $KAFKA_ZK_LOCAL;then
  ZK_clientPort=${ZK_clientPort:-2181}
  OK=$(echo ruok | nc localhost $ZK_clientPort)
  if [ "$OK" == "imok" ]; then
    eval `bin/kafka-topics.sh --zookeeper localhost:2181 --list`
    exit $?
  else
    exit 1
  fi
else
  eval `bin/kafka-topics.sh --zookeeper $SERVER_ZOOKEEPER_CONNECT --list`
  exit $?
fi