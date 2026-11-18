SHELL := /bin/bash
KIND_CLUSTER ?= showcase
PYTHON := app/.venv/Scripts/python.exe
ifeq ($(OS),Windows_NT)
  PYTHON := app/.venv/Scripts/python.exe
else
  PYTHON := app/.venv/bin/python
endif

.PHONY: help venv test lint build cluster terraform-init terraform-apply \
        deploy-dev deploy-prod grafana prometheus smoke clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-18s %s\n", $$1, $$2}'

venv: ## Create venv and install dev dependencies
	python -m venv app/.venv
	$(PYTHON) -m pip install -r app/requirements-dev.txt

test: ## Run unit tests
	$(PYTHON) -m pytest -q app/tests

lint: ## Lint python code
	$(PYTHON) -m ruff check app/ || true

build: ## Build container image locally
	docker build -t showcase-api:dev app/

run: ## Run the app locally (no k8s)
	cd app && uvicorn app:app --reload --port 8000

cluster: ## Create a local kind cluster with 1 control-plane + 2 workers
	kind get clusters | grep -q '^$(KIND_CLUSTER)$$' || kind create cluster --name $(KIND_CLUSTER) --config scripts/kind-config.yaml
	kubectl cluster-info --context kind-$(KIND_CLUSTER)

terraform-init: ## Initialize Terraform
	cd terraform && terraform init

terraform-apply: ## Apply cluster addons (ingress + monitoring)
	cd terraform && terraform apply -auto-approve

deploy-dev: ## Deploy app to dev via Kustomize
	kustomize build k8s/overlays/dev | kubectl apply -f -

deploy-prod: ## Deploy app to prod via Helm
	helm upgrade --install showcase api helm/showcase \
	  --namespace showcase-prod --create-namespace \
	  --set autoscaling.enabled=true \
	  --set ingress.enabled=true \
	  --set image.tag=1.0.0

grafana: ## Port-forward Grafana (admin / admin by default)
	kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

prometheus: ## Port-forward Prometheus
	kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090

smoke: ## Smoke test the app through port-forward
	./scripts/smoke-test.sh

clean: ## Delete the kind cluster
	kind delete cluster --name $(KIND_CLUSTER)
