#!/usr/bin/env bash

source ../lib/functions.sh

check_variable "COMMODORE_SSH_PRIVATE_KEY" $COMMODORE_SSH_PRIVATE_KEY
check_variable "GITLAB_ENDPOINT" $GITLAB_ENDPOINT

# Minikube must be running
MINIKUBE_RUNNING=$(kubectl get nodes | grep minikube)
if [ -z "$MINIKUBE_RUNNING" ]; then
    echo "===> ERROR: Minikube is not running"
    exit 1
fi
echo "===> Minikube running"

echo "===> Find Lieutenant URL"
LIEUTENANT_URL=$(minikube service lieutenant-api -n lieutenant --url | sed 's/http:\/\///g' | awk '{split($0,a,":"); print "http://lieutenant." a[1] ".nip.io:" a[2]} "/"')
if [ -z "$LIEUTENANT_URL" ]; then
    echo "===> ERROR: No LIEUTENANT_URL found"
    exit 1
fi
echo "===> Lieutenant API: $LIEUTENANT_URL"

echo "===> Find Cluster ID"
CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')
if [ -z "$CLUSTER_ID" ]; then
    echo "===> ERROR: No CLUSTER_ID found"
    exit 1
fi
echo "===> CLUSTER_ID: $CLUSTER_ID"

echo "===> Create Lieutenant Objects: Tenant and Cluster"
LIEUTENANT_TOKEN=$(kubectl -n lieutenant get secret $(kubectl -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')

echo "===> Kickstart Commodore"
echo "===> IMPORTANT: When prompted enter your SSH key password"
echo "===> and then the following commands:"
echo "===> $ ssh-keyscan ${GITLAB_ENDPOINT} >> /app/.ssh/known_hosts"
echo "===> $ commodore catalog compile $CLUSTER_ID --push"
kubectl -n lieutenant run commodore-shell \
  --image=docker.io/projectsyn/commodore:latest \
  --env=COMMODORE_API_URL="$LIEUTENANT_URL" \
  --env=COMMODORE_API_TOKEN="$LIEUTENANT_TOKEN" \
  --env=COMMODORE_GLOBAL_GIT_BASE=https://github.com/projectsyn \
  --env=SSH_PRIVATE_KEY="$(cat ${COMMODORE_SSH_PRIVATE_KEY})" \
  --env=CLUSTER_ID="$CLUSTER_ID" \
  --env=GITLAB_ENDPOINT="$GITLAB_ENDPOINT" \
  --tty --stdin --restart=Never --rm --wait \
  --image-pull-policy=Always \
  --command \
  -- /usr/local/bin/entrypoint.sh bash

echo "===> COMMODORE DONE"
