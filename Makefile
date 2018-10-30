.DEFAULT_GOAL := help

DOCKER_ORG           ?= engapa
DOCKER_IMAGE         ?= kafka

SCALA_VERSION        ?= 2.12
KAFKA_VERSION        ?= 2.0.0
ZOO_VERSION          ?= 3.4.13
KUBE_VERSION         ?= v1.11.3
MINIKUBE_VERSION     ?= v0.28.2

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
	  -t $(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION) \
      -t $(DOCKER_ORG)/$(DOCKER_IMAGE):latest .

.PHONY: docker-push
docker-push: ## Publish docker images
	@echo "Don't forget login: docker login -u <username>"
	@docker push $(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION)
	@docker push $(DOCKER_ORG)/$(DOCKER_IMAGE):latest

.PHONY: docker-test
docker-test: ## Test for docker container
	@docker run -d --name kafka $(DOCKER_ORG)/$(DOCKER_IMAGE):$(SCALA_VERSION)-$(KAFKA_VERSION)
	@docker exec -it kafka kafka_server_status.sh
	@docker rm -f kafka > /dev/null 2>&1 || true

.PHONY: k8s-minikube-reqs
k8s-minikube-reqs: ## Install requisites
	@k8s/main.sh minikube
	@k8s/main.sh kubectl

.PHONY: k8s-minikube-run
k8s-minikube-run: ## Run a minikube cluster
	@k8s/main.sh minikube_run

k8s-test: ## Launch tests on a kubernetes cluster
	@k8s/main.sh test-all

.PHONY: minishift-run
minishift-run: ## Launck a minishift cluster
	@k8s/main.sh minikube-run

openshift-test: ## Launch tests on a openshift cluster
	@k8s/main.sh test-all

## TODO: helm, ksonnet