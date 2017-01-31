[![CircleCI](https://circleci.com/gh/engapa/kafka-docker/tree/master.svg?style=svg)](https://circleci.com/gh/engapa/kafka-docker/tree/master)
[![Docker Pulls](https://img.shields.io/docker/pulls/engapa/kafka.svg)](https://hub.docker.com/r/engapa/kafka/)
[![Docker Stars](https://img.shields.io/docker/stars/engapa/kafka.svg)](https://hub.docker.com/r/engapa/kafka/)
[![Docker Layering](https://images.microbadger.com/badges/image/engapa/kafka.svg)](https://microbadger.com/images/engapa/kafka)
# Kafka Docker Image

Kafka docker image

# Getting started



# Build an image

```bash
export SCALA_VERSION="2.12"
export KAFKA_VERSION="0.10.1.1"
$docker build --build-arg SCALA_VERSION=$SCALA_VERSION --build-arg KAFKA_VERSION=$KAFKA_VERSION \
-t engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION} .
```

# Run a container

We have three scripts to use within our container:

* kafka_download.sh
* kafka_setup.sh
* kafka_server.sh

### Setting up

```bash
export SCALA_VERSION="2.12"
export KAFKA_VERSION="0.10.1.1"
$docker run -it engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION} \
 /bin/bash -c "bin/kafka_setup.sh && bin/kafka_server start"
```

### Run local zookeeper

### External zookeeper

# k8s

# Author

Enrique Garcia **engapa@gmail.com**