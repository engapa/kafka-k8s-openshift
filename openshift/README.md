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
$ oc new-app kafka-builder -p IMAGE_STREAM_VERSION="2.12-0.11.0.0" -p GITHUB_REF="v2.12-0.11.0.0"
```

Explore the command `oc new-build` to create a builder via shell command client.

2 - Check that image is ready to use

```sh
$ oc get is -l component=zk [-n project]
NAME    DOCKER REPO                       TAGS           UPDATED
kafka   172.30.1.1:5000/myproject/kafka   2.12-0.11.0.0  1 days ago
```

3 - If you want to use this local/private image for your pod containers then use the "DOCKER REPO" value as `SOURCE_IMAGE` parameter value, and use one of the "TAGS" values as `KAFKA_VERSION` parameter value (e.g: 172.30.1.1:5000/myproject/kafka:latest).

4 - Launch the builder again with another commit or whenever you want:

```sh
$ oc start-build kafka-builder --commit=master
```
## Topologies

We've got at least three ways to deploy a kafka cluster, all of them are based on statefulsets of kubernetes (version >= 1.5) :

### Single All-in-one (zookeeper sidecar)

Both zookeeper and kafka processes running in the same container.

By default when someone launches a container based on this image we'll have these processes running together.

This topology is ver useful for developers or testing purposes.


```bash
$ oc create -f kafka.yaml
$ oc new-app kafka -p SCALE=1 [-p SOURCE_IMAGE="172.30.1.1:5000/myproject/kafka"]
```

You may use the Openshift dashboard if you prefer to do that from a web interface.

### External zookeeper

Deploy kafka brokers with external zookeeper connection.

These env variables are required :

* KAFKA_ZK_LOCAL=false
* SERVER_zookeeper_connect=\<your-zookeeper-nodes\>

This topology is the most convenient in production environments.

### All-in-one (zookeeper cluster sidecar)

A zookeeper cluster with a kafka broker inside each node.
The number of nodes must be a valid quorum for zookeeper (1, 3, 5, ...).

For example if you want to have a quorum of 3 zookeeper nodes , then we'll have got 3 brokers too.

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
$ oc create -f kafka-local.yaml
$ oc new-app kafka [-p parameter=value]
$ minishift console
```

## Cleanup

Remove components of the cluster:

```sh
$ oc delete all,statefulset -l app=<NAME>
```
where NAME is the parameter value provided on creation time.

Note that there are still some resources, the build config (for using images form your private registry) and the persistent volumes and claims (pv, pvc).
Be careful, don't delete the persistent volume claim if you want to use it again in the future and preserve the data, or change de default policy (default is DELETE).

```sh
$ oc delete pv,pvc,bc,is -l component=kafka
```

Remove the templates:

```sh
$ oc delete templates kafka-builder kafka
```






