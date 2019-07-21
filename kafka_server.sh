#!/bin/bash

### Default properties

. kafka_env.sh

KAFKA_PID_FILE=$KAFKA_HOME/kafka.pid
ZOO_PID_FILE=$KAFKA_HOME/zookeeper.pid

function start() {

  . kafka_setup.sh

  if $KAFKA_ZK_LOCAL;then

    mkdir -p ${ZK_dataDir} ${ZK_dataLogDir}
    echo "${SERVER_broker_id:-0}" > $ZK_dataDir/myid

    ZOO_LOG_DIR=${ZOO_LOG_DIR:-${KAFKA_HOME}/zookeeper}
    mkdir -p $ZOO_LOG_DIR

    KAFKA_HEAP_OPTS="${ZOO_HEAP_OPTS:-}" $KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_CONF_DIR/zookeeper.properties > $ZOO_LOG_DIR/zookeeper.out 2>&1 < /dev/null &
    ZOO_PID=$!
    if [ $? -eq 0 ]; then
      echo -n $ZOO_PID > $ZOO_PID_FILE
    else
      echo "Failed to start zookeeper server"
      return 1
    fi
    # Is zookeeper ok
    COUNT_DOWN_ZOO=20

    until [[ $COUNT_DOWN_ZOO -lt 0 ]]; do
      if [[ 'imok' == $(echo ruok | nc 127.0.0.1 $ZK_clientPort) ]]; then
        echo "Zookeeper server is ready ! "
        break;
      fi
      if [[ $COUNT_DOWN_ZOO -eq 0 ]]; then
        echo "No Zookeeper server is ready"
        return 1
      fi
      echo "Waiting for local Zookeper server ..."
      COUNT_DOWN_ZOO=`expr $COUNT_DOWN_ZOO - 1`
      sleep 3
    done
  fi

  $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_CONF_DIR/server.properties "$@" &
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

  $KAFKA_HOME/bin/kafka-server-stop.sh
  if [[ -f $KAFKA_PID_FILE ]]; then
    kill -s TERM $(cat "$KAFKA_PID_FILE")
    rm $KAFKA_PID_FILE
  fi

  sleep 5

  if $KAFKA_ZK_LOCAL;then
    $KAFKA_HOME/bin/zookeeper-server-stop.sh
    if [[ -f $ZOO_PID_FILE ]]; then
      kill -s TERM $(cat "$ZOO_PID_FILE")
      rm $ZOO_PID_FILE
    fi
  fi

  sleep 5
  COUNT_DOWN=9

  until [[ $COUNT_DOWN -lt 0 ]]; do
    KAFKA_JAVA_PIDS=$(ps ax | grep -i 'kafka' | grep java | grep -v grep | awk '{print $1}')
    if [[ -z $KAFKA_JAVA_PIDS ]]; then
      echo "It seems that there is not a kafka server running yet - OK, :-)"
      return 0
    elif [[ $COUNT_DOWN -gt 0 ]]; then
      echo "(${COUNT_DOWN}) Trying stop processes: ${KAFKA_JAVA_PIDS}"
      kill -s TERM $KAFKA_JAVA_PIDS
    else
      echo "(${COUNT_DOWN}) Killing processes: ${KAFKA_JAVA_PIDS}"
      kill -s KILL $KAFKA_JAVA_PIDS
    fi
    COUNT_DOWN=`expr $COUNT_DOWN - 1`
    sleep 3
  done

  return 1

}

trap "stop" SIGHUP SIGINT SIGTERM

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
  *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac