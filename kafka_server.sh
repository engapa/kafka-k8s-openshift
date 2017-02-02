#!/bin/bash

### Default properties

KAFKA_HOME=${KAFKA_HOME:-/opt/kafka}
KAFKA_ZK_LOCAL=${KAFKA_ZK_LOCAL:-true}

KAFKA_PID_FILE=$KAFKA_HOME/kafka.pid
ZOO_PID_FILE=$KAFKA_HOME/zookeeper.pid

function start() {

  if $KAFKA_ZK_LOCAL;then
    ZOO_LOG_DIR=${ZOO_LOG_DIR:-${KAFKA_HOME}/zookeeper}
    mkdir -p $ZOO_LOG_DIR
    bin/zookeeper-server-start.sh config/zookeeper.properties > $ZOO_LOG_DIR/zookeeper.out 2>&1 < /dev/null &
    if [ $? -eq 0 ]; then
      echo -n $! > $ZOO_PID_FILE
    else
      echo "Failed to start zookeeper server"
      return 1
    fi
  fi

  bin/kafka-server-start.sh config/server.properties "$@" &
  KAFKA_PID=$!
  RET_CODE=$?
  if [[ $RET_CODE -eq 0 ]]; then
    echo -n $! > $KAFKA_PID_FILE
  else
    echo "Failed to start kafka server"
    return 1
  fi
  wait $KAFKA_PID

}

function stop() {

  bin/kafka-server-stop.sh
  if [[ -f $KAFKA_PID_FILE ]]; then
    kill -s TERM $(cat "$KAFKA_PID_FILE")
    rm $KAFKA_PID_FILE
  fi

  sleep 5

  if $KAFKA_ZK_LOCAL;then
    bin/zookeeper-server-stop.sh
    if [[ -f $ZOO_PID_FILE ]]; then
      kill -s TERM $(cat "$ZOO_PID_FILE")
      rm $ZOO_PID_FILE
    fi
  fi

  sleep 2
  COUNT_DOWN=0

  until [[ ! $COUNT_DOWN -lt 10 ]]; do
    KAFKA_JAVA_PIDS=$(ps ax | grep -i 'kafka' | grep java | grep -v grep | awk '{print $1}')
    if [[ -z $KAFKA_JAVA_PIDS ]]; then
      echo "It seems that there is not a kafka server running yet - OK, :-)"
      return 0
    elif [[ $COUNT_DOWN -lt 9 ]]; then
      echo "(${COUNT_DOWN}) Trying stop processes: ${KAFKA_JAVA_PIDS}"
      kill -s TERM $KAFKA_JAVA_PIDS
      sleep 2
    else
      echo "(${COUNT_DOWN}) Killing processes: ${KAFKA_JAVA_PIDS}"
      kill -s KILL $KAFKA_JAVA_PIDS
    fi
    COUNT_DOWN=`expr $COUNT_DOWN + 1`
  done

  return 1

}

function status() {

  if $KAFKA_ZK_LOCAL;then
    ZK_clientPort=${ZK_clientPort:-2181}
    eval `timeout 10 bin/kafka-topics.sh --zookeeper localhost:$ZK_clientPort --list`
    return $?
  else
    eval `timeout 10 bin/kafka-topics.sh --zookeeper $SERVER_zookeeper_connect --list`
    return $?
  fi

}


term_handler() {
  stop
}

trap "term_handler" SIGHUP SIGINT SIGTERM


# Main options
case "$1" in
  start)
        shift
        start "$@"
        exit $?
        ;;
  stop)
        stop
        exit $?
        ;;
  restart)
        shift
        stop
        sleep 3
        start "$@"
        exit $?
        ;;
  status)
        status
        STATUS_RET_VAL=$?
        if [[ $STATUS_RET_VAL != 0 ]]; then
          echo "Kafka server is not running -  KO, :-("
        else
          echo "Kafka server is running - OK, :-)"
        fi
        exit $STATUS_RET_VAL
        ;;
  *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
esac