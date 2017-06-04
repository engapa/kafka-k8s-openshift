# Kafka cluster

Kafka cluster deployment.

The resources found here are templates for Openshift catalog.

## Topologies

We've got at least three ways to deploy a kafka cluster, all of them are based on statefulsets of kubernetes (version >= 1.5) :

### Single All-in-one (zookeeper sidecar)

Both zookeeper and kafka processes running in the same container.

By default when someone launches a container based on this image we'll have these processes running together.

This topology is ver useful for developers or testing purposes.


```bash
$ oc create -f kafka.yaml
$ oc new-app kafka -p SCALE=1
```

You may use the Openshift dashboard if you prefer to do that from a web interface.

### External zookeeper

Deploy kafka brokers with external zookeeper connection.

These env variables are required :

* KAFKA_ZK_LOCAL=false
* SERVER_zookeeper_connect=\<your-zookeeper-nodes\>

This topology is the most convenient in production environments.

### Clustered All-in-one (zookeeper cluster sidecar)

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








