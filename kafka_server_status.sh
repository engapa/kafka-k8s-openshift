#!/bin/bash

### bootstrap servers, timeout
timeout=${1:-60}
bootstrap_servers=${2:-"localhost:${SERVER_port}"}

timeout $timeout $KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server $bootstrap_servers --list > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
 echo -e "\033[32mKafka topics list command executed successfully, :-)\033[0m"
 exit 0
else
 echo -e "\033[31mKafka topics list command failed, :-(\033[0m"
 exit 1
fi