#!/usr/bin/env bash

source lib/functions.sh
source lib/k3s.sh

check_variable "GITLAB_TOKEN" $GITLAB_TOKEN
check_variable "GITLAB_ENDPOINT" $GITLAB_ENDPOINT
check_variable "GITLAB_USERNAME" $GITLAB_USERNAME
check_variable "TENANT_ID" $TENANT_ID
check_variable "LIEUTENANT_URL" $LIEUTENANT_URL
check_variable "LIEUTENANT_TOKEN" $LIEUTENANT_TOKEN

# Wait for K3s to be ready
k3d cluster create projectsyn --network host
wait_for_k3s
wait_for_traefik

LIEUTENANT_AUTH="Authorization: Bearer ${LIEUTENANT_TOKEN}"

echo "===> Register this cluster via the API"
CLUSTER_ID=$(curl -s -H "$LIEUTENANT_AUTH" -H "Content-Type: application/json" -X POST --data "{ \"tenant\": \"${TENANT_ID}\", \"displayName\": \"K3s cluster\", \"facts\": { \"cloud\": \"local\", \"distribution\": \"k3s\", \"region\": \"local\" }, \"gitRepo\": { \"url\": \"ssh://git@${GITLAB_ENDPOINT}/${GITLAB_USERNAME}/cluster-gitops1.git\" } }" "${LIEUTENANT_URL}/clusters" | jq -r ".id")
check_variable "CLUSTER_ID" $CLUSTER_ID

echo "===> Retrieve the Steward install URL"
STEWARD_INSTALL=$(curl --header "$LIEUTENANT_AUTH" --silent "${LIEUTENANT_URL}/clusters/${CLUSTER_ID}" | jq -r ".installURL")
echo "===> Steward install URL: $STEWARD_INSTALL"

echo "===> Install Steward in the local k3s cluster"
kubectl apply -f "$STEWARD_INSTALL"

echo "===> Check that Steward is running and that Argo CD Pods are appearing"
kubectl -n syn get pod

echo "===> Check that Argo CD was able to sync the changes"
wait_for_argocd

echo "===> Retrieve the admin password for Argo CD"
kubectl -n syn get secret steward -o json | jq -r .data.token | base64 --decode

echo ""
echo "===> STEWARD DONE"
