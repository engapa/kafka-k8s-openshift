# Kafka cluster

Kafka cluster deployment.

The resources found here are templates for Openshift catalog.

It isn't necessary to clone this repo, you can use the resources with the prefix "https://raw.githubusercontent.com/engapa/kafka-k8s-openshift/master/openshift/" in order to get remote sources directly.

## Building the image

This is an optional step, you can always use the [public images at dockerhub](https://hub.docker.com/r/engapa/kafka) which are automatically uploaded.

Anyway, if you prefer to build the image in your private Openshift registry just follow these instructions:

1 - Create an image builder and build the container image

```sh
$ oc create -f buildconfig.yaml
$ oc new-app kafka-builder -p IMAGE_STREAM_VERSION="2.12-0.11.0.1" -p GITHUB_REF="v2.12-0.11.0.1"
```

Explore the command `oc new-build` to create a builder via shell command client.

2 - Check that image is ready to use

```sh
$ oc get is -l component=zk [-n project]
NAME    DOCKER REPO                       TAGS           UPDATED
kafka   172.30.1.1:5000/myproject/kafka   2.12-0.11.0.1  1 days ago
```

3 - If you want to use this local/private image for your pod containers then use the "DOCKER REPO" value as `SOURCE_IMAGE` parameter value, and use one of the "TAGS" values as `KAFKA_VERSION` parameter value (e.g: 172.30.1.1:5000/myproject/kafka:latest).

4 - Launch the builder again with another commit or whenever you want:

```sh
$ oc start-build kafka-builder --commit=master
```

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
$ oc create -f kafka.yaml
$ oc new-app kafka -p REPLICAS=1 -p ZK_LOCAL=true [-p SOURCE_IMAGE=172.30.1.1:5000/myproject/kafka]
```

> NOTE: params between '[]' characters are optional.

The number of nodes must be a valid quorum for zookeeper (1, 3, 5, ...).
For example, if you want to have a quorum of 3 zookeeper nodes, then we'll have got 3 kafka brokers too.

#### Persistent storage with external Zookeeper

First of all, [deploy a zookeeper cluster](https://github.com/engapa/zookeeper-k8s-openshift).

```bash
$ oc create -f kafka[-zk]-persistent.yaml
$ oc new-app kafka -p SERVER_zookeeper_connect=<zookeeper-nodes> [-p SOURCE_IMAGE=172.30.1.1:5000/myproject/kafka]
```

## Local testing

We recommend to use "minishift" in order to get quickly a ready Openshift deployment.

Check out the Openshift version by typing:

```bash
$ minishift get-openshift-versions
$ minishift config get openshift-version
```

If no version is showed in last command this means that the latest stable version is being used.

```bash
$ minishift config set openshift-version <version>
$ minishift start
$ oc create -f kafka[-zk][-persistent].yaml
$ oc new-app kafka [-p parameter=value]
$ minishift console
```

## Clean up

To remove all resources related to one kafka cluster deployment launch this command:

```sh
$ oc delete all,statefulset[,pvc] -l kafka-name=<name> [-n <namespace>|--all-namespaces]
```
where '<name>' is the value of param NAME. Note that pvc resources are marked as optional in the command,
it's up to you preserver or not the persistent volumes (by default when a pvc is deleted the persistent volume will be deleted as well).
Type the namespace option if you are in a different namespace that resources are, and indicate --all-namespaces option if all namespaces should be considered.

It's possible delete all resources created by using the template:
with cluster created by template name:

```sh
$ oc delete all,statefulset[,pvc] -l template=kafka[-zk][-persistent] [-n <namespace>] [--all-namespaces]
```

Also someone can remove all resources of type kafka, belong to all clusters and templates:

```sh
$ oc delete all,statefulset[,pvc] -l component=kafka [-n <namespace>] [--all-namespaces]
```

And finally if you even want to remove the template:

```sh
$ oc delete template kafka[-zk][-persistent] [-n <namespace>] [--all-namespaces]
```
