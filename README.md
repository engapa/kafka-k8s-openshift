[![CircleCI](https://circleci.com/gh/engapa/kafka-docker/tree/master.svg?style=svg)](https://circleci.com/gh/engapa/kafka-docker/tree/master)
[![Docker Pulls](https://img.shields.io/docker/pulls/engapa/kafka.svg)](https://hub.docker.com/r/engapa/kafka/)
[![Docker Stars](https://img.shields.io/docker/stars/engapa/kafka.svg)](https://hub.docker.com/r/engapa/kafka/)
[![Docker Layering](https://images.microbadger.com/badges/image/engapa/kafka.svg)](https://microbadger.com/images/engapa/kafka)
# Kafka Docker Image

The aim of this project is create/use kafka docker images.

# Build an image

```bash
export KAFKA_HOME="/opt/kafka"
export SCALA_VERSION="2.12"
export KAFKA_VERSION="0.10.1.1"
$docker build --build-arg SCALA_VERSION=$SCALA_VERSION --build-arg KAFKA_VERSION=$KAFKA_VERSION --build-arg KAFKA_HOME=$KAFKA_HOME \
-t engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION} .
```

The **kafka_download.sh** script is used to download the suitable release.
The built docker image will contain a kafka distribution (${SCALA_VERSION}-${KAFKA_VERSION}) under the directory $KAFKA_HOME.

Besides, we've added two scripts more :

* kafka_setup.sh  : Configure kafka and zookeeper dynamically , based on [utils-docker project](https://github.com/engapa/utils-docker)
* kafka_server.sh : A wrapper to manage kafka and zookeeper processes

# Run a container

This image hasn't any `CMD` entry, users are the responsible for launching any command when they are going to run the container.

For example, let's create a container to run kafka and zookeeper all-in-one :

```bash
docker run -it -e "SETUP_DEBUG=true" engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION} \
 /bin/bash -c "kafka_setup.sh && kafka_server.sh start"
Writing environment variables to file :

PREFIX           : SERVER_
DEST_FILE        : /opt/kafka/config/server.properties
EXCLUSIONS       :
CREATE_FILE      : true
OVERRIDE         : true
FROM_SEPARATOR   : _
TO_SEPARATOR     : .
LOWER            : true
.......................................

[DEBUG] [2017-01-31_20:17:26] -  [OVERRIDE] : SERVER_log_dirs --> log.dirs=/opt/kafka/logs
[DEBUG] [2017-01-31_20:17:26] -  [OVERRIDE] : SERVER_zookeeper_connect --> zookeeper.connect=localhost:2181
[DEBUG] [2017-01-31_20:17:26] -  [OVERRIDE] : SERVER_broker_id --> broker.id=-1
.......................................

Writing environment variables to file :

PREFIX           : ZK_
DEST_FILE        : /opt/kafka/config/zookeeper.properties
EXCLUSIONS       :
CREATE_FILE      : true
OVERRIDE         : true
FROM_SEPARATOR   : _
TO_SEPARATOR     : .
LOWER            : false
.......................................

[DEBUG] [2017-01-31_20:17:26] -  [OVERRIDE] : ZK_dataDir --> dataDir=/opt/kafka/zookeeper/data
[DEBUG] [2017-01-31_20:17:26] -  [OVERRIDE] : ZK_clientPort --> clientPort=2181
[DEBUG] [2017-01-31_20:17:26] -  [  ADD   ] : ZK_dataLogDir --> dataLogDir=/opt/kafka/zookeeper/data-log
...
[2017-01-31 20:17:28,150] INFO Socket connection established to localhost/127.0.0.1:2181, initiating session (org.apache.zookeeper.ClientCnxn)
[2017-01-31 20:17:28,308] INFO Session establishment complete on server localhost/127.0.0.1:2181, sessionid = 0x159f62cc8c00000, negotiated timeout = 6000 (org.apache.zookeeper.ClientCnxn)
...
[2017-01-31 20:17:29,646] INFO Kafka version : 0.10.1.1 (org.apache.kafka.common.utils.AppInfoParser)
[2017-01-31 20:17:29,646] INFO Kafka commitId : f10ef2720b03b247 (org.apache.kafka.common.utils.AppInfoParser)
[2017-01-31 20:17:29,647] INFO [Kafka Server 1001], started (kafka.server.KafkaServer)
```

>NOTE: We've pass a SETUP_DEBUG environment variable to view the setup process of config files.

## Setting up

Users can pass parameters to config files just adding environment variables with specific name patterns.

This table collects the patterns of variable names which will are written in each file:

PREFIX     | FILE (${KAFKA_HOME}/config) |         Example
-----------|-----------------------------|-----------------------------
SERVER_    | server.properties           | SERVER_broker_id=1 --> broker.id=1
LOG4J_     | log4j.properties |  LOG4J_log4j_rootLogger=INFO, stdout--> log4j.rootLogger=INFO, stdout
CONSUMER_  | consumer.properties| CONSUMER_zookeeper_connect=127.0.0.1:2181 --> zookeeper.connect=127.0.0.1:2181
PRODUCER_  | producer.properties| PRODUCER_compression_type=none --> compression.type=none
ZK_        | zookeeper.properties | ZK_maxClientCnxns=0 --> maxClientCnxns=0
CONN_CONSOLE_SINK_ |connect-console-sink.properties | CONN_CONSOLE_SINK_tasks_max=1 --> tasks.max=1
CONN_CONSOLE_SOURCE_ | connect-console-source.properties | CONN_CONSOLE_SOURCE_topic=connect-test --> topic=connect-test
CONN_DISTRIB_ | connect-distributed.properties | CONN_DISTRIB_group_id=connect-cluster --> group.id=connect-cluster
CONN_FILE_SINK_   | connect-file-sink.properties | CONN_FILE_SINK_connector_class=FileStreamSink --> connector.class=FileStreamSink
CONN_FILE_SOURCE_ | connect-file-source.properties | CONN_FILE_SOURCE_tasks_max=1 --> tasks.max=1
CONN_LOG4J_ | connect-log4j.properties | CONN_LOG4J_log4j_rootLogger=INFO, stdout --> log4j.rootLogger=INFO, stdout
CONN_STANDALONE_ | connect-standalone.properties | CONN_STANDALONE_bootstrap_servers=localhost:9092 --> bootstrap.servers=localhost:9092
TOOLS_LOG4J_ | tools-log4j.properties | TOOLS_LOG4J_log4j_appender_stderr_Target=System.err --> log4j.appender.stderr.Target=System.err

So we can configure our kafka server in docker run time :

```bash
$docker run -it -d -e "LOG4J_log4j_rootLogger=DEBUG, stdout" -e "SERVER_log_retention_hours=24"\
engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION} /bin/bash -c "kafka_setup.sh && kafka_server.sh start"
```

Also you may use `--env-file` option to load these variables from a file.

And , of course, you could provide your own properties files directly by option `-v` and don't use kafka_setup and kafka_server scripts.

The override option of kafka server is preserved and can used by you :

```bash
docker run -it -e "SETUP_DEBUG=true" engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION} \
 /bin/bash -c "kafka_setup.sh && kafka_server.sh start --override advertised.host.name=blablabla"
 [2017-02-04 19:06:10,504] INFO KafkaConfig values:
	advertised.host.name = blablabla
...
[2017-02-04 19:06:11,693] INFO [Kafka Server 1001], started (kafka.server.KafkaServer)
```

### Run local zookeeper

By default, when someone launches  `kafka_server.sh start` a zookeeper process is started too.
This behaviour is managed by env KAFKA_ZK_LOCAL (whit **true** as default value).

### External zookeeper

If you want to deploy a kafka server w/o localzookeeper the you should provide these env values:

* KAFKA_ZK_LOCAL=false
* SERVER_zookeeper_connect=\<zookeeper_host:zookeeper_port\>\[,\<zookeeper_host:zookeeper_port\>\]

For instance :

```bash
$docker run -it -d -e "KAFKA_ZK_LOCAL=false" -e "SERVER_zookeeper_connect=zookeeperserver1:2181,zookeeperserver2:2181,zookeeperserver3:2181" \
engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION} /bin/bash -c "kafka_setup.sh && kafka_server.sh start"
```

# k8s

In [k8s directory](k8s) there are some examples and utilities for Kubernetes

# Author

Enrique Garcia **engapa@gmail.com**