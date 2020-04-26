.DEFAULT_GOAL := help

DOCKER_ORG           ?= engapa
DOCKER_IMAGE         ?= kafka

SCALA_VERSION        ?= 2.13
KAFKA_VERSION        ?= 2.5.0


.PHONY: help
help: ## Show this help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: ## Clean docker containers and images
	@docker rm -f $$(docker ps -a -f "ancestor=$(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION)" --format '{{.Names}}') > /dev/null 2>&1 || true
	@docker rmi -f $(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION) > /dev/null 2>&1 || true

.PHONY: docker-build
docker-build: ## Build the docker image
	@docker build --no-cache \
	  -t $(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION) .

.PHONY: docker-run
docker-run: ## Create a docker container
	@docker run -d --name kafka $(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION)

.PHONY: docker-test
docker-test: docker-run ## Test for docker container
	@until [ "$$(docker ps --filter 'name=kafka' --filter 'health=healthy' --format '{{.Names}}')" == "kafka" ]; do \
	   sleep 10; \
	   (docker ps --filter 'name=kafka' --format '{{.Names}}' | grep kafka > /dev/null 2>&1) || exit $$?; \
	   echo "Checking healthy status of kafka ..."; \
	done

.PHONY: docker-push
docker-push: ## Publish docker images
	@docker push $(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION)


.PHONY: minikube-install
minikube-install: ## Install minikube and kubectl
	@k8s/main.sh minikube-install
	@k8s/main.sh kubectl-install

.PHONY: minikube-run
minikube-run: ## Run minikube
	@k8s/main.sh minikube-run

.PHONY: minikube-test-zk
minikube-test-zk: ## Launch tests on minikube, within an internal zookeeper cluster
	@k8s/main.sh test-zk

.PHONY: minikube-test-persistent
minikube-test-persistent: ## Launch tests on minikube, within an external zookeeper cluster
	@k8s/main.sh test-persistent

.PHONY: minikube-clean-resources
minikube-clean-resources: ## Clean kafka and zookeeper respources
	@k8s/main.sh clean-resources

.PHONY: minikube-delete
minikube-delete: ## Remove minikube
	@k8s/main.sh minikube-delete

.PHONY: oc-install
oc-install: ## Install oc tools
	@openshift/main.sh oc-install

.PHONY: oc-cluster-run
oc-cluster-run: ## Run a cluster through oc command
	@openshift/main.sh oc-cluster-run

.PHONY: oc-test-zk
oc-test-zk: ## Launch tests on openshift, within an internal zookeeper cluster
	@openshift/main.sh test-zk

.PHONY: oc-clean-resources
oc-clean-resources: ## Clean kafka and zookeeper respources
	@openshift/main.sh clean-resources

.PHONY: oc-test-persistent
oc-test-persistent: ## Launch tests on openshift, within an external zookeeper cluster
	@openshift/main.sh test-persistent

.PHONY: oc-cluster-delete
oc-cluster-clean: ## Remove openshift cluster
	@openshift/main.sh oc-cluster-delete

.PHONY: version
version: ## Get version
	@echo "$(SCALA_VERSION)-$(KAFKA_VERSION)"

## TODO: helm, ksonnet for deploy on kubernetes