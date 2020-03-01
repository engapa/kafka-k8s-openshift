#!/bin/bash -e

### Default properties

# For Zookeeper versions since 3.5, we really need "ruok" to check zookeeper cluster status, but for the future ...
export ZK_4lw_commands_whitelist=*

function zk_local_cluster() {

  # Required envs for replicated mode
  export ZK_tickTime=${ZK_tickTime:-2000}
  export ZK_initLimit=${ZK_initLimit:-5}
  export ZK_syncLimit=${ZK_syncLimit:-2}

  ZOO_SERVER_PORT=${ZOO_SERVER_PORT:-2888}
  ZOO_ELECTION_PORT=${ZOO_ELECTION_PORT:-3888}

  SERVER_zookeeper_connect=''

  for (( i=1; i<=$KAFKA_REPLICAS; i++ )); do
    export ZK_server_$i="$NAME-$((i-1)).$DOMAIN:$ZOO_SERVER_PORT:$ZOO_ELECTION_PORT"
    SERVER_zookeeper_connect=${SERVER_zookeeper_connect}"$NAME-$((i-1)).$DOMAIN:"${ZK_clientPort}","
  done

  export SERVER_zookeeper_connect=${SERVER_zookeeper_connect::-1}

}

if [[ "x$KAFKA_ZK_LOCAL" == "xtrue" ]];then
  export ZK_dataDir=${ZK_dataDir:-$KAFKA_HOME/zookeeper/data}
  export ZK_dataLogDir=${ZK_dataLogDir:-$KAFKA_HOME/zookeeper/data-log}
  export ZK_clientPort=${ZK_clientPort:-2181}
  export SERVER_zookeeper_connect=${SERVER_zookeeper_connect:-"localhost:${ZK_clientPort}"}
fi

HOST=`hostname -s`
DOMAIN=`hostname -d`

if [ $KAFKA_REPLICAS -gt 1 ];then
  if [[ $HOST =~ (.*)-([0-9]+)$ ]]; then
    NAME=${BASH_REMATCH[1]}
    ORD=${BASH_REMATCH[2]}
    export SERVER_broker_id=$((ORD+1))
    if $KAFKA_ZK_LOCAL;then
      zk_local_cluster
    fi
  elif $KAFKA_ZK_LOCAL; then
    echo "Unable to create local Zookeeper. Name of host doesn't match with pattern: (.*)-([0-9]+). Consider Kubernetes StatefulSets."
    exit 1
  fi
fi

export SERVER_log_dirs=${SERVER_log_dirs:-$KAFKA_HOME/logs}