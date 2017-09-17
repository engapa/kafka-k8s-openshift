#!/bin/bash

### Default properties

. kafka_env.sh

timeout -t 30 $KAFKA_HOME/bin/kafka-topics.sh --zookeeper $SERVER_zookeeper_connect --list > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
 echo -e "\033[32mKafka server is running, :-)\033[0m"
 exit 0
else
 echo -e "\033[31mKafka server is not running, :-(\033[0m"
 exit 1
fi