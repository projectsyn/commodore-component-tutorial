#!/usr/bin/env bash

source ../lib/functions.sh
source ../lib/k3s.sh

check_variable "COMMODORE_SSH_PRIVATE_KEY" $COMMODORE_SSH_PRIVATE_KEY
check_variable "GITLAB_ENDPOINT" $GITLAB_ENDPOINT

# Wait for K3s to be ready
wait_for_k3s

# Set the INGRESS_IP variable
set_ingress_ip

LIEUTENANT_URL="http://lieutenant.${INGRESS_IP}.nip.io/"
check_variable "LIEUTENANT_URL" $LIEUTENANT_URL

CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')
check_variable "CLUSTER_ID" $CLUSTER_ID

echo "===> Create Lieutenant Objects: Tenant and Cluster"
LIEUTENANT_TOKEN=$(kubectl -n lieutenant get secret $(kubectl -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')

echo "===> Kickstart Commodore"
echo "===> IMPORTANT: When prompted enter your SSH key password"
echo "===> and then the following commands:"
echo "===> $ ssh-keyscan ${GITLAB_ENDPOINT} >> /app/.ssh/known_hosts"
echo "===> $ commodore catalog compile $CLUSTER_ID --push"
kubectl -n lieutenant run commodore-shell \
  --image=docker.io/projectsyn/commodore:v0.2.0 \
  --env=COMMODORE_API_URL="${LIEUTENANT_URL}" \
  --env=COMMODORE_API_TOKEN=${LIEUTENANT_TOKEN} \
  --env=COMMODORE_GLOBAL_GIT_BASE=https://github.com/projectsyn \
  --env=SSH_PRIVATE_KEY="$(cat ${COMMODORE_SSH_PRIVATE_KEY})" \
  --env=CLUSTER_ID=${CLUSTER_ID} \
  --env=GITLAB_ENDPOINT=${GITLAB_ENDPOINT} \
  --tty --stdin --restart=Never --rm --wait \
  --image-pull-policy=Always \
  --command \
  -- /usr/local/bin/entrypoint.sh bash

echo "===> COMMODORE DONE"
