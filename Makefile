.DEFAULT_GOAL := help

DOCKER_ORG           ?= engapa
DOCKER_IMAGE         ?= kafka

SCALA_VERSION        ?= 2.12
KAFKA_VERSION        ?= 2.0.0
ZOO_VERSION          ?= 3.4.13

KUBE_VERSION         ?= v1.11.3
MINIKUBE_VERSION     ?= v0.30.0

OC_VERSION           ?= v3.11.0
MINISHIFT_VERSION    ?= v3.11.0

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
	   echo "Checking healthy status of kafka ..."; \
	   sleep 20; \
	done

.PHONY: docker-push
docker-push: ## Publish docker images
	@docker push $(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION)

.PHONY: minikube-reqs
minikube-reqs: ## Install requisites of kubernetes (minikebe)
	@k8s/main.sh minikube
	@k8s/main.sh kubectl

.PHONY: minikube-run
minikube-run: ## Run a kubernetes cluster (minikube)
	@k8s/main.sh minikube_run

.PHONY: minikube-test
minikube-test: ## Launch tests on minikube
	@k8s/main.sh test-all

.PHONY: minishift-reqs
minishift-reqs: ## Install requisites of Openshift (minishift)
	@k8s/main.sh minishift
	@k8s/main.sh oc

.PHONY: minishift-run
minishift-run: ## Launck an Openshift cluster (minishift)
	@k8s/main.sh minikube-run

.PHONY: minishift-test
minishift-test: ## Launch tests on minishift
	@openshift/main.sh test-all

## TODO: helm, ksonnet