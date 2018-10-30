#!/usr/bin/env bash

set -e

SCALA_VERSION=${SCALA_VERSION:-"2.12"}
KAFKA_VERSION=${KAFKA_VERSION:-"2.0.0"}
KAFKA_IMAGE=${KAFKA_IMAGE:-"engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION}"}
ZK_IMAGE="engapa/zookeeper:${ZOO_VERSION:-'3.4.13'}"

MINISHIFT_VERSION=${MINISHIFT_VERSION:-"v1.26.1"}

CHANGE_MINISHIFT_NONE_USER="true"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SLEEP_TIME=8
MAX_ATTEMPTS=10

function oc()
{
  # Download oc
  curl -LO https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
  tar -xvzf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
  mv openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc ./oc
  rm -rf openshift-origin-client-tools*
  chmod a+x oc
}

function minishift()
{
  # Download minishift
  curl -LO https://github.com/minishift/minishift/releases/download/v1.26.1/minishift-1.26.1-linux-amd64.tgz
  tar -xzf minishift-1.26.1-linux-amd64.tgz
  mv minishift-1.26.1-linux-amd64/minishift ./minishift
  rm -rf minishift-*
  chmod a+x minishift
}

function minishift-run()
{

  export MINISHIFT_HOME=$HOME
  export CHANGE_MINISHIFT_NONE_USER=true
  mkdir -p $HOME/.kube
  touch $HOME/.kube/config

  export KUBECONFIG=$HOME/.kube/config
  sudo -E ./minishift start --memory 5000 --cpus 4

  # Waiting for Minikube
  for i in {1..150}; do # timeout for 5 minutes
     ./oc version &> /dev/null
     if [ $? -ne 1 ]; then
        break
    fi
    sleep 2
  done

}

# $1: zookeper image
function zk_install()
{

  echo "Deploying zookeeper ..."
  ./oc run zk --image $ZK_IMAGE --port 2181 --labels="component=kafka,app=zk"
  ./oc expose deploy zk --name zk --port=2181 --cluster-ip=None --labels="component=kafka,app=zk"
  echo "Zookeeper running on zk.default.svc.cluster.local"
  # TODO: Wait until kubectl get pods --field-selector=status.phase=Running

}

# $1 : file
# $2 : Number of replicas
function check()
{

  attempts=0
  JSONPATH_STSETS='replicasOk={.items[?(@.kind=="StatefulSet")].status.readyReplicas}'
  until [ "$(./oc get -f $1 -o jsonpath="$JSONPATH_STSETS" 2>&1)" == "replicasOk=$2" ]; do
    sleep $SLEEP_TIME
    attempts=`expr $attempts + 1`
    if [[ $attempts -gt $MAX_ATTEMPTS ]]; then
      echo "ERROR: Max number of attempts was reached (${MAX_ATTEMPTS})"
      exit 1
    fi
   echo "Retry [${attempts}] ... "
  done
}

function test()
{
  # Given
  file=$DIR/kafka.yaml
  conf $file
  # When
  ./oc create -f $file
  ./oc new-app kafka -p REPLICAS=1
  # Then
  check $file 3
  # TODO: Use kafka client to validate e2e
}

function test-persistent()
{
  # Given
  install_zk
  file=$DIR/kafka-persistent.yaml
  # When
  ./oc create -f $file
  ./oc new-app kafka -p REPLICAS=1
  # Then
  check $file 3
}

function test-zk-persistent()
{
  # Given
  file=$DIR/kafka-zk-persistent.yaml
  # When
  ./oc create -f $file
  ./oc new-app kafka -p REPLICAS=1
  # Then
  check file 1
}

function test-all()
{
  test && ./oc delete --force=true -l component=kafka -l app=kafka all
  test-persistent && ./oc delete --force=true -l component=kafka -l app=kafka all,pv,pvc
  test-zk-persistent
}

function clean() # Destroy minishift vm
{
  echo "Cleaning ...."
  ./minishift delete
}

function help() # Show a list of functions
{
    declare -F -p | cut -d " " -f 3
}

if [ "_$1" = "_" ]; then
    help
else
    "$@"
fi
