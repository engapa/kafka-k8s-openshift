#!/usr/bin/env bash

set -e

SCALA_VERSION=${SCALA_VERSION:-"2.13"}
KAFKA_VERSION=${KAFKA_VERSION:-"2.5.0"}
KAFKA_IMAGE=${KAFKA_IMAGE:-"engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION}"}
ZOO_VERSION='3.6.0'
ZK_IMAGE="engapa/zookeeper:${ZOO_VERSION}"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


function oc-install()
{
  # Download oc
  curl -LO https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
  tar -xvzf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
  mv openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc ./oc
  rm -rf openshift-origin-client-tools*
  chmod a+x oc
  sudo mv oc /usr/local/bin/oc
}

function oc-cluster-run()
{

  # Add internal insecure registry
  sudo sed -i 's#^ExecStart=.*#ExecStart=/usr/bin/dockerd --insecure-registry='172.30.0.0/16' -H fd://#' /lib/systemd/system/docker.service
  sudo systemctl daemon-reload
  sudo systemctl restart docker

  # Run openshift cluster
  oc cluster up --enable=[*]

  # Waiting for cluster
  for i in {1..150}; do # timeout for 5 minutes
    oc cluster status &> /dev/null
    if [[ $? -ne 1 ]]; then
       break
    fi
    sleep 2
  done

  oc login -u system:admin
  oc adm policy add-scc-to-group privileged system:serviceaccounts:myproject
  oc create -f $DIR/kafka-zk.yaml
  oc create -f $DIR/kafka-persistent.yaml

}

function build_local_image()
{

  oc new-build --name kafka --strategy docker --binary --docker-image "openjdk:8-jre-alpine"
  oc start-build kafka --from-dir $DIR/.. --follow

}

# $1 : Number of replicas
function check()
{

  SLEEP_TIME=10
  MAX_ATTEMPTS=50
  ATTEMPTS=0
  READY_REPLICAS="0"
  REPLICAS=${1:-1}
  until [[ "$READY_REPLICAS" == "$REPLICAS" ]]; do
    sleep $SLEEP_TIME
    ATTEMPTS=`expr $ATTEMPTS + 1`
    if [[ $ATTEMPTS -gt $MAX_ATTEMPTS ]]; then
      echo "ERROR: Max number of attempts was reached (${MAX_ATTEMPTS})"
      exit 1
    fi
    READY_REPLICAS=$(oc get statefulset -l component=${2:-kafka} -o jsonpath='{.items[?(@.kind=="StatefulSet")].status.readyReplicas}' 2>&1)
   echo "[${ATTEMPTS}/${MAX_ATTEMPTS}] - Ready replicas : ${READY_REPLICAS:-0}/$REPLICAS ... "
  done
  oc get all
}

function test-zk()
{
  # Given
  REPLICAS=${1:-1}
  # When
  oc new-app --template=kafka-zk -p REPLICAS=$REPLICAS -p SOURCE_IMAGE="engapa/kafka"
  # Then
  check $REPLICAS

}

function test-persistent()
{
  # Given
  echo "Installing zookeeper cluster ..."
  oc create -f https://raw.githubusercontent.com/engapa/zookeeper-k8s-openshift/v$ZOO_VERSION/openshift/zk.yaml
  oc new-app --template=zk -p ZOO_REPLICAS=1 -p SOURCE_IMAGE="engapa/zookeeper"
  check 1 zk

  echo "Installing kafka cluster with persistent storage ..."
  REPLICAS=${1:-1}
  for i in $(seq 1 ${REPLICAS});do
  cat << PV | oc create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
 name: kafka-persistent-data-disk-$i
 contents: data
 labels:
   component: kafka
spec:
 capacity:
  storage: 1Gi
 accessModes:
  - ReadWriteOnce
 hostPath:
  path: /tmp/oc/kafka-persistent-data-disk-$i
PV
  done
  # When
  oc new-app --template=kafka-persistent -p REPLICAS=${REPLICAS} -p SOURCE_IMAGE="engapa/kafka"
  # Then
  check ${REPLICAS}
  oc get pv,pvc
}

function test-all()
{
  REPLICAS=$1
  test $REPLICAS && oc delete -l component=kafka all
  test-persistent $REPLICAS && oc delete -l component=kafka all,pv,pvc
}

function clean-resources()
{
  echo "Cleaning resources ...."
  oc delete -l component=kafka all,pv,pvc
  oc delete -l component=zk all,pv,pvc
}

function oc-cluster-delete()
{
  echo "Stopping cluster ...."
  oc cluster down
}

function help() # Show a list of functions
{
    declare -F -p | cut -d " " -f 3
}

if [[ "_$1" = "_" ]]; then
    help
else
    "$@"
fi
