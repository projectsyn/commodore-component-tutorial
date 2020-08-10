#!/usr/bin/env bash

source lib/functions.sh
source lib/k3s.sh

check_variable "GITLAB_TOKEN" $GITLAB_TOKEN
check_variable "GITLAB_ENDPOINT" $GITLAB_ENDPOINT
check_variable "GITLAB_USERNAME" $GITLAB_USERNAME
check_variable "TENANT_ID" $TENANT_ID
check_variable "LIEUTENANT_URL" $LIEUTENANT_URL
check_variable "LIEUTENANT_TOKEN" $LIEUTENANT_TOKEN
check_variable "COMMODORE_SSH_PRIVATE_KEY" $COMMODORE_SSH_PRIVATE_KEY

# Wait for K3s to be ready
k3d cluster create projectsyn --network host
wait_for_k3s
wait_for_traefik

LIEUTENANT_AUTH="Authorization: Bearer ${LIEUTENANT_TOKEN}"

echo "===> Register this cluster via the API"
CLUSTER_ID=$(curl -s -H "$LIEUTENANT_AUTH" -H "Content-Type: application/json" -X POST --data "{ \"tenant\": \"${TENANT_ID}\", \"displayName\": \"K3s cluster\", \"facts\": { \"cloud\": \"local\", \"distribution\": \"k3s\", \"region\": \"local\" }, \"gitRepo\": { \"url\": \"ssh://git@${GITLAB_ENDPOINT}/${GITLAB_USERNAME}/tutorial-cluster-k3s.git\" } }" "${LIEUTENANT_URL}/clusters" | jq -r ".id")
check_variable "CLUSTER_ID" $CLUSTER_ID

echo "===> Kickstart Commodore"
echo "===> IMPORTANT: When prompted enter your SSH key password"
kubectl --context minikube -n lieutenant run commodore-shell \
  --image=docker.io/projectsyn/commodore:v0.2.0 \
  --env=COMMODORE_API_URL="$LIEUTENANT_URL" \
  --env=COMMODORE_API_TOKEN="$LIEUTENANT_TOKEN" \
  --env=COMMODORE_GLOBAL_GIT_BASE="https://github.com/$GITHUB_USERNAME" \
  --env=SSH_PRIVATE_KEY="$(cat ${COMMODORE_SSH_PRIVATE_KEY})" \
  --env=CLUSTER_ID="$CLUSTER_ID" \
  --env=GITLAB_ENDPOINT="$GITLAB_ENDPOINT" \
  --tty --stdin --restart=Never --rm --wait \
  --image-pull-policy=Always \
  --command \
  -- /usr/local/bin/entrypoint.sh bash -c "ssh-keyscan $GITLAB_ENDPOINT >> /app/.ssh/known_hosts; commodore catalog compile $CLUSTER_ID --push"

echo "===> COMMODORE DONE"

echo "===> Check the validity of the bootstrap token"
wait_for_token "$CLUSTER_ID"

echo "===> Retrieve the Steward install URL"
STEWARD_INSTALL=$(curl --header "$LIEUTENANT_AUTH" --silent "${LIEUTENANT_URL}/clusters/${CLUSTER_ID}" | jq -r ".installURL")
echo "===> Steward install URL: $STEWARD_INSTALL"

echo "===> Install Steward in the local k3s cluster"
kubectl --context k3d-projectsyn apply -f "$STEWARD_INSTALL"

echo "===> Check that Steward is running and that Argo CD Pods are appearing"
kubectl --context k3d-projectsyn -n syn get pod

echo "===> Check that Argo CD was able to sync the changes"
wait_for_argocd k3d-projectsyn

echo "===> Retrieve the admin password for Argo CD"
kubectl --context k3d-projectsyn -n syn get secret steward -o json | jq -r .data.token | base64 --decode

echo ""
echo "===> STEWARD DONE"
