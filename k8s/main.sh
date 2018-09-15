#!/usr/bin/env bash

set -e

SCALA_VERSION=${SCALA_VERSION:-"2.12"}
KAFKA_VERSION=${KAFKA_VERSION:-"2.0.0"}
KAFKA_IMAGE=${KAFKA_IMAGE:-"engapa/kafka:${SCALA_VERSION}-${KAFKA_VERSION}"}
MINIKUBE_VERSION=${MINIKUBE_VERSION:-"v0.28.2"}
KUBE_VERSION=${KUBE_VERSION:-"v1.11.3"}

CHANGE_MINIKUBE_NONE_USER="true"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ZK_IMAGE="engapa/zookeeper:3.4.13"

SLEEP_TIME=8
MAX_ATTEMPTS=10


function install(){

  if [[ "${KUBE_VERSION}" == 'latest' ]]; then
    KUBE_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
  fi

  # Download kubectl.
  curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/

  # Download minikube.
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64
  chmod +x minikube && sudo mv minikube /usr/local/bin/

  minikube version
  sudo minikube start --vm-driver=none --kubernetes-version=$KUBE_VERSION  --memory 4096
  sudo minikube update-context

  JSONPATH_NODES='{range .items[*]}{.metadata.name}:{range .status.conditions[*]}{.type}={.status};{end}{end}'
  attempts=0
  until kubectl get nodes -o jsonpath="$JSONPATH_NODES" 2>&1 | grep -q "Ready=True"; do
   sleep $SLEEP_TIME
   attempts=`expr $attempts + 1` 
   if [[ $attempts -gt $MAX_ATTEMPTS ]]; then
     echo "ERROR: Max number of attempts was reached (${MAX_ATTEMPTS})"
     exit 1
   fi
  done

  # Check kubernetes info
  kubectl version
  kubectl cluster-info
}

function conf(){

  sed -i -e "s/image:.*/image: $KAFKA_IMAGE/" $1

}

# $1: zookeper image
function install_zk(){

  echo "Deploying zookeeper ..."
  kubectl run zk --image $ZK_IMAGE --port 2181 --labels="component=kafka,app=zk"
  kubectl expose deploy zk --name zk --port=2181 --cluster-ip=None --labels="component=kafka,app=zk"
  echo "Zookeeper running on zk.default.svc.cluster.local"
  # TODO: Wait until kubectl get pods --field-selector=status.phase=Running

}

# $1 : file
# $2 : Number of replicas
function check(){

  attempts=0
  JSONPATH_STSETS='replicasOk={.items[?(@.kind=="StatefulSet")].status.readyReplicas}'
  until [ "$(kubectl get -f $1 -o jsonpath="$JSONPATH_STSETS" 2>&1)" == "replicasOk=$2" ]; do
    sleep $SLEEP_TIME
    attempts=`expr $attempts + 1`
    if [[ $attempts -gt $MAX_ATTEMPTS ]]; then
      echo "ERROR: Max number of attempts was reached (${MAX_ATTEMPTS})"
      exit 1
    fi
   echo "Retry [${attempts}] ... "
  done
}

function test(){
  # Given
  file=$DIR/kafka.yaml
  conf $file
  # When
  kubectl create -f $file
  # Then
  check $file 3
  # TODO: Use kafka client to validate e2e
}

function test-persistent(){
  # Given
  install_zk
  file=$DIR/kafka-persistent.yaml
  # When
  kubectl create -f $file
  # Then
  check $file 3
}

function test-zk-persistent(){
  # Given
  file=$DIR/kafka-zk-persistent.yaml
  # When
  kubectl create -f $file
  # Then
  check file 1
}

function test-all(){
  test && kubectl delete --force=true -l component=kafka -l app=kafka all
  test-persistent && kubectl delete --force=true -l component=kafka -l app=kafka all,pv,pvc
  test-zk-persistent
}

function clean(){
  echo "Cleaning ...."
  minikube delete
}

# Main options
case "$1" in
  install)
    install
    ;;
  test)
    test
    ;;
  test-persistent)
    test-persistent
    ;;
  test-zk-persistent)
    test-zk-persistent
    ;;
  test-all)
    test-all
    ;;
  clean)
    clean
    ;;
  *)
    echo "Usage: $0 {install|test|test-persistent|test-zk-persistent|test-all|clean}"
    exit 1
esac