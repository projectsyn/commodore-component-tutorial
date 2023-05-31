#!/usr/bin/env bash

# shellcheck disable=SC1091
source lib/functions.sh
source lib/minikube.sh

echo "===> Find Tenant ID"
TENANT_ID=$(kubectl --context minikube -n lieutenant get tenant | grep t- | awk 'NR==1{print $1}')
check_variable "TENANT_ID" "$TENANT_ID"

echo "===> Removing all clusters"
# shellcheck disable=SC2207
CLUSTERS=($(kubectl --context minikube -n lieutenant get cluster -o jsonpath="{$.items[*].metadata.name}"))
for CLUSTER in "${CLUSTERS[@]}"; do
    kubectl --context minikube -n lieutenant delete cluster "$CLUSTER"
done

echo "===> Removing tenant"
kubectl --context minikube -n lieutenant delete tenant "$TENANT_ID"

echo "===> Waiting 20 seconds for the removal of GitLab repositories"
sleep 20

minikube delete
k3d cluster delete projectsyn
kind delete cluster --name projectsyn
killall ngrok
