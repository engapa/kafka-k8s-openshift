#!/bin/bash -e

### Default properties

HOST=`hostname -s`
DOMAIN=`hostname -d`
KAFKA_CONF_DIR=${KAFKA_HOME}/config
DEBUG=${DEBUG_SETUP:-false}

function config_files() {

  wget -q https://raw.githubusercontent.com/engapa/utils-docker/master/common-functions.sh
  . common-functions.sh

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

function print_zk_servers() {

  for (( i=1; i<=$KAFKA_REPLICAS; i++ )); do
    ZK_SERVER_PORT=${ZK_SERVER_PORT:-2888}
    ZK_ELECTION_PORT=${ZK_ELECTION_PORT:-3888}
    echo "server.$i=$NAME-$((i-1)).$DOMAIN:$ZK_SERVER_PORT:$ZK_ELECTION_PORT"
  done

}

function check_config() {

  if $KAFKA_ZK_LOCAL;then
    mkdir -p ${ZK_dataDir} ${ZK_dataLogDir}
    echo "${SERVER_BROKER_ID}" >> ${ZK_dataDir}/myid
    if [ ! -z ZK_HEAP_OPTS ]; then
      sed -r -i "s/(export KAFKA_HEAP_OPTS)=\"(.*)\"/\1=\"$ZK_HEAP_OPTS\"/g" ${KAFKA_HOME}/bin/zookeeper-server-start.sh
      unset ZK_HEAP_OPTS
    fi
    echo "unset KAFKA_HEAP_OPTS" >> ${KAFKA_HOME}/bin/zookeeper-server-start.sh
  fi

  if [ $KAFKA_REPLICAS -gt 1 ];then
    if [[ $HOST =~ (.*)-([0-9]+)$ ]]; then
      NAME=${BASH_REMATCH[1]}
      ORD=${BASH_REMATCH[2]}
      export SERVER_BROKER_ID=$((ORD+1))
      if $KAFKA_ZK_LOCAL;then
        print_zk_servers >> ${KAFKA_CONF_DIR}/zookeeper.properties
      fi
    else
     echo "Failed to extract ordinal from hostname $HOST"
     exit 1
    fi
  fi

  if [[ -z "$SERVER_BROKER_ID" ]]; then
    export SERVER_BROKER_ID=-1
  fi

}

check_config && config_files

exec "$@"