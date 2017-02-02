#!/bin/bash -e

### Default properties

HOST=`hostname -s`
DOMAIN=`hostname -d`
KAFKA_HOME=${KAFKA_HOME:-/opt/kafka}
KAFKA_CONF_DIR=$KAFKA_HOME/config
KAFKA_ZK_LOCAL=${KAFKA_ZK_LOCAL:-true}

export SERVER_log_dirs=${SERVER_LOG_DIRS:-$KAFKA_HOME/logs}

function config_files() {

  . ${KAFKA_HOME}/bin/kafka_common_functions.sh

  DEBUG=${SETUP_DEBUG:-false}
  LOWER=${SETUP_LOWER:-false}

  # Server
  PREFIX=SERVER_ DEST_FILE=${KAFKA_CONF_DIR}/server.properties env_vars_in_file

  # Log4j
  PREFIX=LOG4J_ DEST_FILE=${KAFKA_CONF_DIR}/log4j.properties env_vars_in_file

  # Consumer
  PREFIX=CONSUMER_ DEST_FILE=${KAFKA_CONF_DIR}/consumer.properties env_vars_in_file

  # Producer
  PREFIX=PRODUCER_ DEST_FILE=${KAFKA_CONF_DIR}/producer.properties env_vars_in_file

  # Zookeeper
  PREFIX=ZK_ DEST_FILE=${KAFKA_CONF_DIR}/zookeeper.properties env_vars_in_file

  # Connect
  PREFIX=CONN_CONSOLE_SINK_ DEST_FILE=${KAFKA_CONF_DIR}/connect-console-sink.properties env_vars_in_file
  PREFIX=CONN_CONSOLE_SOURCE_ DEST_FILE=${KAFKA_CONF_DIR}/connect-console-source.properties env_vars_in_file
  PREFIX=CONN_DISTRIB_ DEST_FILE=${KAFKA_CONF_DIR}/connect-distributed.properties env_vars_in_file
  PREFIX=CONN_FILE_SINK_ DEST_FILE=${KAFKA_CONF_DIR}/connect-file-sink.properties env_vars_in_file
  PREFIX=CONN_FILE_SOURCE_ DEST_FILE=${KAFKA_CONF_DIR}/connect-file-source.properties env_vars_in_file
  PREFIX=CONN_LOG4J_ DEST_FILE=${KAFKA_CONF_DIR}/connect-log4j.properties env_vars_in_file
  PREFIX=CONN_STANDALONE_ DEST_FILE=${KAFKA_CONF_DIR}/connect-standalone.properties env_vars_in_file

  # Tools log4j
  PREFIX=TOOLS_LOG4J_ DEST_FILE=${KAFKA_CONF_DIR}/tools-log4j.properties env_vars_in_file

}

function zk_local_cluster_setup() {

  # Required envs for replicated mode
  export ZK_tickTime=${ZK_tickTime:-2000}
  export ZK_initLimit=${ZK_initLimit:-5}
  export ZK_syncLimit=${ZK_syncLimit:-2}

  SERVER_zookeeper_connect=''

  for (( i=1; i<=$KAFKA_REPLICAS; i++ )); do
    ZK_server_port=${ZK_server_port:-2888}
    ZK_election_port=${ZK_election_port:-3888}
    echo "server.$i=$NAME-$((i-1)).$DOMAIN:$ZK_server_port:$ZK_election_port" >> ${KAFKA_CONF_DIR}/zookeeper.properties
    SERVER_zookeeper_connect=${SERVER_zookeeper_connect}"$NAME-$((i-1)).$DOMAIN:$ZK_clientPort,"
  done

  export SERVER_zookeeper_connect=${SERVER_zookeeper_connect::-1}

}

function check_config() {

  SERVER_broker_id=0

  if $KAFKA_ZK_LOCAL;then
    export ZK_dataDir=${ZK_dataDir:-$KAFKA_HOME/zookeeper/data}
    export ZK_dataLogDir=${ZK_dataLogDir:-$KAFKA_HOME/zookeeper/data-log}
    mkdir -p ${ZK_dataDir} ${ZK_dataLogDir}
    export ZK_clientPort=${ZK_clientPort:-2181}
    export SERVER_zookeeper_connect=${SERVER_zookeeper_connect:-"localhost:${ZK_clientPort}"}
  fi

  if [ $KAFKA_REPLICAS -gt 1 ];then
    if [[ $HOST =~ (.*)-([0-9]+)$ ]]; then
      NAME=${BASH_REMATCH[1]}
      ORD=${BASH_REMATCH[2]}
      SERVER_broker_id=$((ORD+1))
      if $KAFKA_ZK_LOCAL;then
        zk_local_cluster_setup
      fi
    else
     echo "Failed to extract ordinal from hostname $HOST"
     exit 1
    fi
  fi

  if $KAFKA_ZK_LOCAL;then
    echo "${SERVER_broker_id}" >> ${ZK_dataDir}/myid
    if [ ! -z $ZOO_HEAP_OPTS ]; then
      sed -r -i "s/(export KAFKA_HEAP_OPTS)=\"(.*)\"/\1=\"$ZOO_HEAP_OPTS\"/g" ${KAFKA_HOME}/bin/zookeeper-server-start.sh
      unset ZOO_HEAP_OPTS
    fi
    echo "unset KAFKA_HEAP_OPTS" >> ${KAFKA_HOME}/bin/zookeeper-server-start.sh
  fi

}

check_config && config_files
