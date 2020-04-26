# Kafka Docker Image 
[![Build status](https://circleci.com/gh/engapa/kafka-k8s-openshift/tree/master.svg?style=svg "Build status")](https://circleci.com/gh/engapa/kafka-k8s-openshift/tree/master)
[![Docker Pulls](https://img.shields.io/docker/pulls/engapa/kafka.svg)](https://hub.docker.com/r/engapa/kafka/)
[![Docker Layering](https://images.microbadger.com/badges/image/engapa/kafka.svg)](https://microbadger.com/images/engapa/kafka)
[![Docker Version](https://images.microbadger.com/badges/version/engapa/kafka.svg)](https://microbadger.com/images/engapa/kafka)
![OSS](https://badges.frapsoft.com/os/v1/open-source.svg?v=103 "We love OpenSource")

This project is meant to create an optimised docker image to run kafka containers as 'statefulset' into kubernetes/openshift.

Obviously, the docker image can be used locally for testing or development purposes.

## Build and publish a kafka docker image

To get a docker image ready with default values type:

```bash
$ make clean-all docker-build docker-test docker-push 
```
To get your own image:
```bash
$ export KAFKA_HOME="/opt/kafka"
$ export SCALA_VERSION="2.13"
$ export KAFKA_VERSION="2.5.0"
$ docker build --build-arg SCALA_VERSION=$SCALA_VERSION --build-arg KAFKA_VERSION=$KAFKA_VERSION --build-arg KAFKA_HOME=$KAFKA_HOME \
-t your-org/kafka:${SCALA_VERSION}-${KAFKA_VERSION} .
```

> NOTE: build-args are optional arguments if you want different values from default ones in the Dockerfile

The built docker image will contain a kafka distribution (${SCALA_VERSION}-${KAFKA_VERSION}) under the directory $KAFKA_HOME.

The provided scripts are:

* **kafka_download.sh** : This script is used to download the suitable release.
* **kafka_env.sh** : It purpose is load the default environments variables.
* **kafka_setup.sh** : Configure kafka and zookeeper dynamically , based on [utils-docker project](https://github.com/engapa/utils-docker)
* **kafka_server.sh** : A central script to manage kafka and optional zookeeper processes.
* **kafka_server_status.sh** : Checks kafka server status.

Public docker images are available [HERE](https://cloud.docker.com/repository/docker/engapa/kafka/tags) 

## Getting started with a single docker container locally

The example bellow shows you how to run an all-in-one docker kafka container (with zookeeper as internal sidecar):

```bash
$ docker run -it -p 9092:9092 -p 2181:2181 \
  -e "SETUP_DEBUG=true" \
  -e "SERVER_advertised_listeners=PLAINTEXT://localhost:9092" \
  -e "SERVER_listener_security_protocol_map=PLAINTEXT:PLAINTEXT" \
  -e "SERVER_listeners=PLAINTEXT://0.0.0.0:9092" \
  -h kafka engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION}

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
[2017-01-31 20:17:29,646] INFO Kafka version : 2.3.0 (org.apache.kafka.common.utils.AppInfoParser)
[2017-01-31 20:17:29,646] INFO Kafka commitId : f10ef2720b03b247 (org.apache.kafka.common.utils.AppInfoParser)
[2017-01-31 20:17:29,647] INFO [Kafka Server 1001], started (kafka.server.KafkaServer)
```

>NOTE: We've passed a SETUP_DEBUG environment variable (SETUP_DEBUG=true) to view the setup process details.

### Setting up

Users can provide parameters to config files just adding environment variables with specific name patterns.

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

So we can configure our kafka server via environment variables directly:

```bash
$ docker run -it -d -e "LOG4J_log4j_rootLogger=DEBUG, stdout" -e "SERVER_log_retention_hours=24"\
engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION}
```

Also you may use `--env-file` option to load these variables from a file.

And, of course, you could provide your own property files directly by option `-v` with the suitable properties files.

The override option of kafka server is preserved and anybody can use it on this way:

```bash
$ docker run -it \
  -e "SETUP_DEBUG=true" \
  -h kafka engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION} \
 /bin/bash -c "kafka_server.sh start --override advertised.host.name=kafka"
 [2017-02-04 19:06:10,504] INFO KafkaConfig values:
	advertised.host.name = kafka
...
[2017-02-04 19:06:11,693] INFO [Kafka Server 1001], started (kafka.server.KafkaServer)
```

#### Run local zookeeper

By default a zookeeper process is started too, as we said previously.
This behaviour is managed by the env variable KAFKA_ZK_LOCAL (defaults to "true").

#### External zookeeper

If you want to deploy a kafka server without a local zookeeper then you should provide these env values:

* KAFKA_ZK_LOCAL=false
* SERVER_zookeeper_connect=\<zookeeper_host:zookeeper_port\>\[,\<zookeeper_host:zookeeper_port\>\]

For instance:

```bash
$ docker run -it \
  -e "KAFKA_ZK_LOCAL=false" \
  -e "SERVER_zookeeper_connect=zookeeperserver1:2181,zookeeperserver2:2181,zookeeperserver3:2181" \
  engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION}
```

## Kubernetes

In [k8s directory](k8s) there are some examples and utilities for Kubernetes

## Openshift

In [openshift directory](openshift) there are some resources for Openshift.

## Extra Dockers

Another great kafka docker images can be found at:

- https://hub.docker.com/r/spotify/kafka/
- https://hub.docker.com/r/wurstmeister/kafka

## Author

Enrique Garcia **engapa@gmail.com**
