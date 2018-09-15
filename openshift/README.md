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
$ oc new-app kafka-builder -p IMAGE_STREAM_VERSION="2.12-2.0.0" -p GITHUB_REF="v2.12-1.1.0"
```

Explore the command `oc new-build` to create a builder via shell command client.

2 - Check that image is ready to use

```sh
$ oc get is -l component=zk [-n project]
NAME    DOCKER REPO                       TAGS           UPDATED
kafka   172.30.1.1:5000/myproject/kafka   2.12-2.0.0  1 days ago
```

3 - If you want to use this local/private image from containers on other projects then use the "\<project\>/NAME" value as `SOURCE_IMAGE` parameter value, and use one value of "TAGS" as `ZOO_VERSION` parameter value (e.g: myproject/zookeeper:3.4.10).

4 - \[Optional\] Launch the builder again with another commit or whenever you want:

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

## Examples
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

We recommend to use [minishift](https://github.com/minishift/minishift) in order to get quickly a standalone Openshift cluster.

Running Openshift cluster:

```bash
$ minishift update
$ minishift version
minishift v1.6.0+7a71565
$ minishift start [options]
...
Starting OpenShift using openshift/origin:v3.6.0 ...
Pulling image openshift/origin:v3.6.0
...
$ minishift openshift version
openshift v3.6.0+c4dd4cf
kubernetes v1.6.1+5115d708d7
etcd 3.2.1
```
>NOTE: minishift has configured the oc client correctly to connect to local Openshift cluster properly.

It's possible to start an Openshift machine by the CLI directly, try `oc cluster up --create-machine`,
or if you want to use a specific docker machine rather than create a VM then type `oc cluster up --docker-machine=<machine-name>`.

Now Openshift cluster is ready to we could deploy the kafka cluster by the web console or through the shell command client (CLI):

1 - Using the web console:

```bash
$ minishift console
```

The URL is in the output lines of `minishift start` command.

For the first time enter a username and password, and create a project.
Once we are in the project go to section **Import YAML / JSON** and write or select the content/file of [our template](buildconfig.yaml) to build the docker image.

Type next command to get the same effect:

== TRICK: Change permissions of default scc, `oc eidt scc restricted` and change runAsUser.type to RunAsAny ==

```bash
$ oc process -f buildconfig.yaml | oc create -f -
```

2 - Launch kafka cluster creation:

```bash
$ oc create -f kafka[-zk][-persistent].yaml
$ oc new-app kafka [-p parameter=value]
```

## Clean up

To remove all resources related to one kafka cluster deployment launch this command:

```sh
$ oc delete all,statefulset[,pvc] -l app=<name> [-n <namespace>|--all-namespaces]
```
where '\<name\>' is the value of param NAME. Note that pvc resources are marked as optional in the command,
it's up to you preserver or not the persistent volumes (by default when a pvc is deleted the persistent volume will be deleted as well).
Type the namespace option if you are in a different namespace that resources are, and indicate --all-namespaces option if all namespaces should be considered.

It's possible delete all resources created from this template:

```sh
$ oc delete all,statefulset[,pvc] -l template=kafka[-zk][-persistent] [-n <namespace>] [--all-namespaces]
```

Also someone can remove all resources of type kafka, belong to all clusters and templates:

```sh
$ oc delete all,statefulset[,pvc] -l component=kafka [-n <namespace>] [--all-namespaces]
```

To remove the templates:

```sh
$ oc delete template kafka-builder
$ oc delete template kafka[-zk][-persistent] [-n <namespace>] [--all-namespaces]
```
