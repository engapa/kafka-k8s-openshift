# Kafka cluster

Kafka cluster deployment.

The resources here are templates for Openshift catalog.

It isn't necessary to clone this repo, you can use the resources directly trough the URLs ("https://raw.githubusercontent.com/engapa/kafka-k8s-openshift/master/openshift/\<resource\>".

## Requirements

- [oc](https://github.com/openshift/origin/releases) (v3.11)
- [minihift](https://github.com/minishift/minishift) (v1.34.2)

### DEV environment

We'll use only opensource, that's 'openshift origin'.

[Minishift](https://github.com/minishift/minishift) is the simplest way to get a local Openshift installation on our workstation.
After install the command client check everything is alright to continue:

```bash
$ minishift version
minishift v1.34.2+83ebaab
$ minishift start [options]
...
$ minishift openshift version
openshift v3.11.0+57f8760-31
```
>NOTE: minishift has configured the oc client correctly to connect to local Openshift cluster properly.

```bash
oc version
oc v3.11.0+0cbc58b
kubernetes v1.11.0+d4cacc0
features: Basic-Auth

Server https://192.168.2.32:8443
kubernetes v1.11.0+d4cacc0
```

Login with admin user and provide a password:

```bash
$ oc login -u admin -p xxxxx
```

Create a new project:

```bash
$ oc new-project test 
```

You may use the Openshift dashboard (`minishift console`) if you prefer to do those steps through the web interface.

> TRICK: Login as cluster admin: `oc login -u system:admin -n default`,
 change permissions of default scc `oc edit scc restricted` and change runAsUser.type value to RunAsAny.
 
For local environment we'll use a non persistent deployments (kafka.yaml)

### PROD environment

To connect to external cluster we need to know the URL to login with your credentials.

For production environments we'll use zookeeper and kafka deployments with persistence.

We recommend you to use zookeeper template **zk-persistent.yaml** at https://github.com/engapa/zookeeper-k8s-openshift/tree/master/openshift.

This means that although pods are destroyed all data are safe under persistent volumes, and when pod are recreated the volumes will be attached again.

The statefulset objects have an "antiaffinity" pod scheduler policy so pods will be allocated on separated nodes.
It's required the same number of nodes that the max value of parameter `ZOO_REPLICAS` or `KAFKA_REPLICAS`.

## Building the image

This is a recommended step, although you can always use the [public images at dockerhub](https://hub.docker.com/r/engapa/kafka) which are automatically uploaded with CI of this project.

To build and save a docker image of kafka in your private Openshift registry just follow these instructions:

1 - Create an image builder and build the container image

```bash
$ oc create -f buildconfig.yaml
$ oc new-app kafka-builder -p GITHUB_REF="v2.13-2.5.0" -p IMAGE_STREAM_VERSION="2.13-2.3.0"
```
If you want to get an image from another git commit:

```bash
$ oc start-build kafka-builder --commit=master
```

2 - Check that image is ready:

```bash
$ oc get is -l component=zk [-n project]
NAME    DOCKER REPO                       TAGS           UPDATED
kafka   172.30.1.1:5000/test/kafka      2.13-2.5.0      1 days ago
```

**NOTE**: If you want to use this local/private image from containers on other projects then use the "\<project\>/NAME" value as `SOURCE_IMAGE` parameter value, and use one value of "TAGS" as `KAFKA_VERSION` parameter value (e.g: test/kafka:2.13-2.5.0).

## Topologies

We've got two ways to deploy a kafka cluster (and Ephemeral and Persistent modes according the storage type that you prefer):

Users can choose how to connect to a zookeeper cluster by configuring these parameters:

* KAFKA_ZK_LOCAL: set to 'true' value if an internal zookeeper process should be run. Change to 'false' if you have a reachable zookeeper cluster to connect to.
* SERVER_zookeeper_connect=\<your-zookeeper-nodes\>. This property is required if `KAFKA_ZK_LOCAL=false` in other case the connection string will be auto-generated.

The resource `kafka.yaml` can be launched with internal (`KAFKA_ZK_LOCAL=true`) or external zookeeper (`KAFKA_ZK_LOCAL=false` and `SERVER_zookeeper_connect`).
Both cases haven't persistent storage and would be appropriated for testing purposes.

For production environments we recommend you to use the template in file `kafka-persistent` (`KAFKA_ZK_LOCAL=false` and `SERVER_zookeeper_connect` with zookeeper services).
In both cases we'll have persistent storage (even for the zookeeper process).

### Examples

#### Ephemeral cluster with Zookeeper sidecar (DEV environment)

Optionally users can choose run an internal zookeeper cluster by configuring these parameters:

* KAFKA_ZK_LOCAL=true
* SERVER_zookeeper_connect: This property is not required, it will be auto-generated internally.

```bash
$ oc create -f kafka.yaml
$ oc new-app kafka -p REPLICAS=1 -p ZK_LOCAL=true -p SOURCE_IMAGE=172.30.1.1:5000/test/kafka
```

The number of nodes must be a valid quorum for zookeeper (1, 3, 5, ...).
For example, if you want to have a quorum of 3 zookeeper nodes, then we'll have got 3 kafka brokers too.

#### Persistent storage with external Zookeeper (PROD environment)

First of all, [deploy a zookeeper cluster](https://github.com/engapa/zookeeper-k8s-openshift).

```bash
$ oc create -f kafka-persistent.yaml
$ oc new-app kafka -p SERVER_zookeeper_connect=<zookeeper-nodes> -p SOURCE_IMAGE=172.30.1.1:5000/test/kafka
```

## Clean up

To remove all resources related to one kafka cluster deployment launch this command:

```bash
$ oc delete all,statefulset[,pvc] -l app=<name> [-n <namespace>|--all-namespaces]
```
where '\<name\>' is the value of param NAME. Note that pvc resources are marked as optional in the command,
it's up to you preserver or not the persistent volumes (by default when a pvc is deleted the persistent volume will be deleted as well).
Type the namespace option if you are in a different namespace that resources are, and indicate --all-namespaces option if all namespaces should be considered.

It's possible delete all resources created from this template:

```bash
$ oc delete all,statefulset[,pvc] -l template=kafka[-zk][-persistent] [-n <namespace>] [--all-namespaces]
```

Also someone can remove all resources of type kafka, belong to all clusters and templates:

```bash
$ oc delete all,statefulset[,pvc] -l component=kafka [-n <namespace>] [--all-namespaces]
```

To remove the templates:

```bash
$ oc delete template kafka-builder
$ oc delete template kafka[-zk][-persistent] [-n <namespace>] [--all-namespaces]
```
