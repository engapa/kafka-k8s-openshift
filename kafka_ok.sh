#!/bin/bash -e

if $KAFKA_ZK_LOCAL;then
  ZK_CLIENT_PORT=${ZK_CLIENT_PORT:-2181}
  OK=$(echo zk_ruok | nc 127.0.0.1 $ZK_CLIENT_PORT)
  if [ "$OK" == "zk_imok" ]; then
    exit 0
  else
    exit 1
  fi
fi

KAFKA_ADVERTISE_PORT=${KAFKA_ADVERTISE_PORT:-9092}
OK=$(echo kafka_ruok | nc 127.0.0.1 $KAFKA_PORT)
if [ "$OK" == "kafka_imok" ]; then
  exit 0
else
  exit 1
fi