# Kubernetes resources

Here we have some examples of resources that may be deployed on your kubernetes environment.

Tests were done using the version 1.18 of kubernetes.

## Topologies

We've got two ways to deploy a kafka cluster (and Ephemeral and Persistent modes according the storage type that you prefer):

Users can choose how to connect to a zookeeper cluster by configuring these parameters:

* KAFKA_ZK_LOCAL: set to 'true' value if an internal zookeeper process should be run. Change to 'false' if you have a reachable zookeeper cluster to connect to.
* SERVER_zookeeper_connect=\<your-zookeeper-nodes\>. This property is required if `KAFKA_ZK_LOCAL=false` in other case the connection string will be auto-generated.

The resource `kafka.yaml` can be launched with internal (`KAFKA_ZK_LOCAL=true`) or external (`KAFKA_ZK_LOCAL=false` and `SERVER_zookeeper_connect`) zookeeper.
Both cases haven't persistent storage and would be appropriated for testing purposes.

For production environments we recommend you to use resources with suffix `persistent` (`KAFKA_ZK_LOCAL=false` and `SERVER_zookeeper_connect`) or `zk-persistent` (`KAFKA_ZK_LOCAL=true`).
In both cases we'll have persistent storage (even for the zookeeper process).

### Examples
#### Ephemeral cluster with Zookeeper sidecar

Optionally users can choose run an internal zookeeper cluster by configuring these parameters:

* KAFKA_ZK_LOCAL=true
* SERVER_zookeeper_connect: This property is not required, it will be auto-generated internally.

```bash
$ kubectl create -f kafka.yaml
```

> NOTE: params between '[]' characters are optional.

The number of nodes must be a valid quorum for zookeeper (1, 3, 5, ...).
For example, if you want to have a quorum of 3 zookeeper nodes, then we'll have got 3 kafka brokers too.

#### Persistent storage with external Zookeeper

First of all, [deploy a zookeeper cluster](https://github.com/engapa/zookeeper-k8s-openshift).

```bash
$ kubectl create -f kafka[-zk]-persistent.yaml
```

## Local testing

We recommend to use "minikube" in order to get quickly a ready kafka cluster.

Install and setup you local kubernetes cluster:

```bash
$ minikube get-k8s-versions
$ minikube config get kubernetes-version
```

If no version is showed in last command this means that the latest stable version is being used.

```bash
[$ minikube config set kubernetes-version <version>]
$ minikube start
$ kubectl create -f kafka.yaml
$ minikube dashboard
```

## Clean up

To remove all resources related to one kafka cluster deployment launch this command:

```bash
$ kubectl delete all,statefulset[,pvc] -l app=<name> [-n <namespace>|--all-namespaces]
```
where '<name>' is the value of param NAME. Note that pvc resources are marked as optional in the command,
it's up to you preserver or not the persistent volumes (by default when a pvc is deleted the persistent volume will be deleted as well).
Type the namespace option if you are in a different namespace that resources are, and indicate --all-namespaces option if all namespaces should be considered.

It's possible delete all resources created by using the template:
with cluster created by template name:

```bash
$ kubectl delete all,statefulset[,pvc] -l template=kafka[-zk][-persistent] [-n <namespace>] [--all-namespaces]
```

Also someone can remove all resources of type kafka, belong to all clusters and templates:

```bash
$ kubectl delete all,statefulset[,pvc] -l component=kafka [-n <namespace>] [--all-namespaces]
```

And finally if you even want to remove the template:

```bash
$ kubectl delete template kafka[-zk][-persistent] [-n <namespace>] [--all-namespaces]
```
