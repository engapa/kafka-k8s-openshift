#!/bin/bash -e

### Default properties

HOST=`hostname -s`
KAFKA_HOME=${KAFKA_HOME:-/opt/kafka}
KAFKA_CONF_DIR=$KAFKA_HOME/config
DEBUG=${DEBUG_SETUP:-false}
KAFKA_ZK_LOCAL=${KAFKA_ZK_LOCAL:-true}

export SERVER_LOG_DIRS=${SERVER_LOG_DIRS:-$KAFKA_HOME/logs}

function config_files() {

  . ${KAFKA_HOME}/bin/kafka_common_functions.sh

  # Server
  PREFIX=SERVER_ DEST_FILE=${KAFKA_CONF_DIR}/server.properties DEBUG=${DEBUG} env_vars_in_file

  # Log4j
  PREFIX=LOG4J_ DEST_FILE=${KAFKA_CONF_DIR}/log4j.properties DEBUG=${DEBUG} env_vars_in_file

  # Consumer
  PREFIX=CONSUMER_ DEST_FILE=${KAFKA_CONF_DIR}/log4j.properties DEBUG=${DEBUG} env_vars_in_file

  # Producer
  PREFIX=PRODUCER_ DEST_FILE=${KAFKA_CONF_DIR}/log4j.properties DEBUG=${DEBUG} env_vars_in_file

  # Zookeeper
  PREFIX=ZK_ DEST_FILE=${KAFKA_CONF_DIR}/zookeeper.properties LOWER=false EXLUSIONS=ZK_HEAP_OPTS DEBUG=${DEBUG} env_vars_in_file

  # Connect
  PREFIX=CONN_CONSOLE_SINK_ DEST_FILE=${KAFKA_CONF_DIR}/connect-console-sink.properties DEBUG=${DEBUG} env_vars_in_file
  PREFIX=CONN_CONSOLE_SOURCE_ DEST_FILE=${KAFKA_CONF_DIR}/connect-console-source.properties DEBUG=${DEBUG} env_vars_in_file
  PREFIX=CONN_DISTRIB_ DEST_FILE=${KAFKA_CONF_DIR}/connect-distributed.properties DEBUG=${DEBUG} env_vars_in_file
  PREFIX=CONN_FILE_SINK_ DEST_FILE=${KAFKA_CONF_DIR}/connect-file-sink.properties DEBUG=${DEBUG} env_vars_in_file
  PREFIX=CONN_FILE_SOURCE_ DEST_FILE=${KAFKA_CONF_DIR}/connect-file-source.properties DEBUG=${DEBUG} env_vars_in_file
  PREFIX=CONN_LOG4J_ DEST_FILE=${KAFKA_CONF_DIR}/connect-log4j.properties DEBUG=${DEBUG} env_vars_in_file
  PREFIX=CONN_STANDALONE_ DEST_FILE=${KAFKA_CONF_DIR}/connect-standalone.properties DEBUG=${DEBUG} env_vars_in_file

  # Tools log4j
  PREFIX=TOOLS_LOG4J_ DEST_FILE=${KAFKA_CONF_DIR}/tools-log4j.properties DEBUG=${DEBUG} env_vars_in_file

}

function zk_local_cluster_setup() {

  # Required envs for replicated mode
  export ZK_tickTime=${ZK_tickTime:-2000}
  export ZK_initLimit=${ZK_initLimit:-5}
  export ZK_syncLimit=${ZK_syncLimit:-2}

  for (( i=1; i<=$KAFKA_REPLICAS; i++ )); do
    ZK_SERVER_PORT=${ZK_SERVER_PORT:-2888}
    ZK_ELECTION_PORT=${ZK_ELECTION_PORT:-3888}
    echo "server.$i=$NAME-$((i-1)):$ZK_SERVER_PORT:$ZK_ELECTION_PORT" >> ${KAFKA_CONF_DIR}/zookeeper.properties
    SERVER_ZOOKEEPER_CONNECT=$SERVER_ZOOKEEPER_CONNECT + "$NAME-$((i-1)):$ZK_clientPort,"
  done

  export SERVER_ZOOKEEPER_CONNECT=${SERVER_ZOOKEEPER_CONNECT::-1}

}

function check_config() {

  if $KAFKA_ZK_LOCAL;then
    export ZK_dataDir=${ZK_dataDir:-$KAFKA_HOME/zookeeper/data}
    export ZK_dataLogDir=${ZK_dataLogDir:-$KAFKA_HOME/zookeeper/data-log}
    mkdir -p ${ZK_dataDir} ${ZK_dataLogDir}
    export ZK_clientPort=${ZK_clientPort:-2181}
    export SERVER_ZOOKEEPER_CONNECT=${SERVER_ZOOKEEPER_CONNECT:-"localhost:${ZK_clientPort}"}
  fi

  if [ $KAFKA_REPLICAS -gt 1 ];then
    if [[ $HOST =~ (.*)-([0-9]+)(.*) ]]; then
      NAME=${BASH_REMATCH[1]}
      ORD=${BASH_REMATCH[2]}
      SERVER_BROKER_ID=$((ORD+1))
      if $KAFKA_ZK_LOCAL;then
        zk_local_cluster_setup
      fi
    else
     echo "Failed to extract ordinal from hostname $HOST"
     exit 1
    fi
  fi

  if $KAFKA_ZK_LOCAL;then
    echo "${SERVER_BROKER_ID:-0}" >> ${ZK_dataDir}/myid
    if [ ! -z $ZK_HEAP_OPTS ]; then
      sed -r -i "s/(export KAFKA_HEAP_OPTS)=\"(.*)\"/\1=\"$ZK_HEAP_OPTS\"/g" ${KAFKA_HOME}/bin/zookeeper-server-start.sh
      unset ZK_HEAP_OPTS
    fi
    echo "unset KAFKA_HEAP_OPTS" >> ${KAFKA_HOME}/bin/zookeeper-server-start.sh
  fi

  if [[ -z "$SERVER_BROKER_ID" ]]; then
    export SERVER_BROKER_ID=-1
  fi

}

check_config && config_files
