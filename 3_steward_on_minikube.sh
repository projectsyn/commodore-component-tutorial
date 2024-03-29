#!/usr/bin/env bash

# shellcheck disable=SC1091
source lib/functions.sh
source lib/minikube.sh

check_minikube

echo "===> Find Cluster ID"
CLUSTER_ID=$(kubectl --context minikube -n lieutenant get cluster | grep Minikube | awk 'NR==1{print $1}')
check_variable "CLUSTER_ID" "$CLUSTER_ID"

echo "===> Find Lieutenant URL"
LIEUTENANT_URL=$(curl http://localhost:4040/api/tunnels --silent | jq -r '.["tunnels"][0]["public_url"]')
check_variable "LIEUTENANT_URL" "$LIEUTENANT_URL"

echo "===> Find Lieutenant API token"
LIEUTENANT_TOKEN=$(kubectl --context minikube -n lieutenant get secret token-secret -o go-template='{{.data.token | base64decode}}')
check_variable "LIEUTENANT_TOKEN" "$LIEUTENANT_TOKEN"
LIEUTENANT_AUTH="Authorization: Bearer $LIEUTENANT_TOKEN"

echo "===> Check the validity of the bootstrap token"
wait_for_token "$CLUSTER_ID"

echo "===> Retrieve the Steward install URL"
STEWARD_INSTALL=$(curl --header "$LIEUTENANT_AUTH" --silent "${LIEUTENANT_URL}/clusters/${CLUSTER_ID}" | jq -r ".installURL")
echo "===> Steward install URL: $STEWARD_INSTALL"

echo "===> Install Steward in the local Minikube"
kubectl --context minikube apply -f "$STEWARD_INSTALL"

echo "===> Check that Steward is running and that Argo CD Pods are appearing"
kubectl --context minikube -n syn get pod

echo ""
echo "===> STEWARD DONE"
