#!/usr/bin/env bash

set -e

SCALA_VERSION=${SCALA_VERSION:-"2.12"}
KAFKA_VERSION=${KAFKA_VERSION:-"1.0.0"}
MINIKUBE_VERSION=${MINIKUBE_VERSION:-"v0.24.1"}
KUBE_VERSION=${KUBE_VERSION:-"v1.8.0"}

CHANGE_MINIKUBE_NONE_USER="true"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SLEEP_TIME=5
MAX_ATTEMPTS=10

VOLUME="
kind: PersistentVolume
apiVersion: v1
metadata:
  name: data-kafka-INDEX
  labels:
    component: kafka
spec:
  storageClassName: anything
  capacity:
    storage: SIZE
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: '/tmp/data-kafka-INDEX'
"

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
  sudo minikube start --vm-driver=none --kubernetes-version=$KUBE_VERSION
  sudo minikube update-context

  JSONPATH_NODES='{range .items[*]}{.metadata.name}:{range .status.conditions[*]}{.type}={.status};{end}{end}'
  attempts=0
  until kubectl get nodes -o jsonpath="$JSONPATH_NODES" 2>&1 | grep -q "Ready=True"; do
   sleep $SLEEP_TIME
   attempts=`expr $attempts + 1` 
   if [[ $attempts -gt $MAX_ATTEMPTS ]]; then
     echo "Max number of attempts was reached (${MAX_ATTEMPTS})"
     exit 1
   fi
  done

  # Check kubernetes info
  kubectl version
  kubec cluster-info
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
      echo "Max number of attempts was reached (${MAX_ATTEMPTS})"
      exit 1
    fi
   echo "Retry [${attempts}] ... "
  done
}

function test(){
  # Given
  file=$DIR/kafka.yaml
  # When
  kubectl create -f $file
  # Then
  check $file 3
  # TODO: Use kafka client to validate e2e
}

function test-persistent(){
  # Given
  echo "Creating persistent volumes /tmp/data-kafka (100Mi)"
  for i in {0..2}; do mkdir -p /tmp/data-kafka-$i && echo $VOLUME | sed "s/INDEX/$i/g" | sed "s/SIZE/100Mi/g" | kubectl create -f -; done
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
  test && kubectl delete --force=true -l component=kafka all
  test-persistent && kubectl delete --force=true -l component=kafka all && kubectl delete pv,pvc --all
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