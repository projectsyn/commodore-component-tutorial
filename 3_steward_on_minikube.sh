#!/usr/bin/env bash

source lib/functions.sh
source lib/minikube.sh

check_minikube

echo "===> Find Cluster ID"
CLUSTER_ID=$(kubectl --context minikube -n lieutenant get cluster | grep Minikube | awk 'NR==1{print $1}')
check_variable "CLUSTER_ID" $CLUSTER_ID

echo "===> Find Lieutenant URL"
LIEUTENANT_URL=$(minikube service lieutenant-api -n lieutenant --url | sed 's/http:\/\///g' | awk '{split($0,a,":"); print "http://lieutenant." a[1] ".nip.io:" a[2] }')
check_variable "LIEUTENANT_URL" $LIEUTENANT_URL

echo "===> Find Lieutenant API token"
LIEUTENANT_TOKEN=$(kubectl --context minikube -n lieutenant get secret $(kubectl --context minikube -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')
check_variable "LIEUTENANT_TOKEN" $LIEUTENANT_TOKEN
LIEUTENANT_AUTH="Authorization: Bearer ${LIEUTENANT_TOKEN}"

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
