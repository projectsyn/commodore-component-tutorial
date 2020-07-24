#!/usr/bin/env bash

# Minikube must be running
MINIKUBE_RUNNING=$(kubectl get nodes | grep minikube)
if [ -z "$MINIKUBE_RUNNING" ]; then
    echo "===> ERROR: Minikube is not running"
    exit 1
fi
echo "===> Minikube running"

echo "===> Find Cluster ID"
CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')
if [ -z "$CLUSTER_ID" ]; then
    echo "===> ERROR: No CLUSTER_ID found"
    exit 1
fi
echo "===> CLUSTER_ID: $CLUSTER_ID"

echo "===> Find Lieutenant URL"
LIEUTENANT_URL=$(minikube service lieutenant-api -n lieutenant --url | sed 's/http:\/\///g' | awk '{split($0,a,":"); print "http://lieutenant." a[1] ".nip.io:" a[2] }')
if [ -z "$LIEUTENANT_URL" ]; then
    echo "===> ERROR: No LIEUTENANT_URL found"
    exit 1
fi
echo "===> Lieutenant API: $LIEUTENANT_URL"

echo "===> Find Lieutenant API token"
LIEUTENANT_TOKEN=$(kubectl -n lieutenant get secret $(kubectl -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')
if [ -z "$LIEUTENANT_TOKEN" ]; then
    echo "===> ERROR: No LIEUTENANT_TOKEN found"
    exit 1
fi
LIEUTENANT_AUTH="Authorization: Bearer ${LIEUTENANT_TOKEN}"

echo "===> Checking validity of bootstrap tokens"
TOKEN_VALID=$(kubectl -n lieutenant get cluster "$CLUSTER_ID" -o jsonpath="{.status.bootstrapToken.tokenValid}")
if [ "$TOKEN_VALID" != "true" ]; then
    echo "===> ERROR: Invalid token"
    exit 1
fi
TOKEN_VALID_UNTIL=$(kubectl -n lieutenant get cluster "$CLUSTER_ID" -o jsonpath="{.status.bootstrapToken.validUntil}")
echo "===> Token valid until $TOKEN_VALID_UNTIL"

echo "===> Retrieve the Steward install URL"
STEWARD_INSTALL=$(curl --header "$LIEUTENANT_AUTH" --silent "${LIEUTENANT_URL}/clusters/${CLUSTER_ID}" | jq -r ".installURL")
echo "===> Steward install URL: $STEWARD_INSTALL"

echo "===> Install Steward in the local Minikube"
kubectl apply -f "$STEWARD_INSTALL"

echo "===> Check the validity of the bootstrap token"
TOKEN_VALID=$(kubectl -n lieutenant get cluster "$CLUSTER_ID" -o jsonpath="{.status.bootstrapToken.tokenValid}")
if [ "$TOKEN_VALID" != "false" ]; then
    echo "===> ERROR: Invalid token"
    exit 1
fi
echo "===> Bootstrap token valid"

echo "===> Check that Steward is running and that Argo CD Pods are appearing"
kubectl -n syn get pod

echo "===> Check that Argo CD was able to sync the changes"
kubectl -n syn get app root -o jsonpath="{.status.sync.status}"

echo "===> Retrieve the admin password for Argo CD"
kubectl -n syn get secret steward -o json | jq -r .data.token | base64 --decode

echo ""
echo "===> STEWARD DONE"
