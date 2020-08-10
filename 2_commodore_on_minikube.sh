#!/usr/bin/env bash

source lib/functions.sh
source lib/minikube.sh

check_variable "COMMODORE_SSH_PRIVATE_KEY" $COMMODORE_SSH_PRIVATE_KEY
check_variable "GITLAB_ENDPOINT" $GITLAB_ENDPOINT
check_variable "GITHUB_USERNAME" $GITHUB_USERNAME

check_minikube

echo "===> Find commodore-defaults repository fork on GitHub"
GITHUB_COMMODORE_URL=https://github.com/$GITHUB_USERNAME/commodore-defaults
GITHUB_COMMODORE_DEFAULTS=$(curl $GITHUB_COMMODORE_URL --head --silent | grep "HTTP/1.1 200 OK")
if [ -z "$GITHUB_COMMODORE_DEFAULTS" ]; then
  echo "===> ERROR: You must fork the https://github.com/projectsyn/commodore-defaults before running this script"
  exit 1
fi
echo "===> OK: commodore defaults forked: $GITHUB_COMMODORE_DEFAULTS"

echo "===> Find Lieutenant URL"
LIEUTENANT_URL=$(minikube service lieutenant-api -n lieutenant --url | sed 's/http:\/\///g' | awk '{split($0,a,":"); print "http://lieutenant." a[1] ".nip.io:" a[2]} "/"')
check_variable "LIEUTENANT_URL" $LIEUTENANT_URL

echo "===> Find Cluster ID"
CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')
check_variable "CLUSTER_ID" $CLUSTER_ID

echo "===> Find Lieutenant Token"
LIEUTENANT_TOKEN=$(kubectl -n lieutenant get secret $(kubectl -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')

echo "===> Kickstart Commodore"
echo "===> IMPORTANT: When prompted enter your SSH key password"
kubectl -n lieutenant run commodore-shell \
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