#!/usr/bin/env bash

# shellcheck disable=SC1091
source lib/functions.sh
source lib/minikube.sh

check_variable "GITLAB_TOKEN" "$GITLAB_TOKEN"
check_variable "GITLAB_ENDPOINT" "$GITLAB_ENDPOINT"
check_variable "GITLAB_USERNAME" "$GITLAB_USERNAME"

# Minikube must be running
minikube start --disk-size 60g --cpus 4
check_minikube

echo "===> Creating namespace"
kubectl create namespace lieutenant

echo "===> CRDs (global scope)"
kubectl apply -k "github.com/projectsyn/lieutenant-operator/config/crd?ref=v1.3.0"

echo "===> Operator deployment"
kubectl -n lieutenant apply -k "github.com/projectsyn/lieutenant-operator/config/samples/deployment?ref=v1.3.0"

echo "===> Operator configuration"
kubectl -n lieutenant set env deployment/lieutenant-operator -c lieutenant-operator \
    DEFAULT_DELETION_POLICY=Delete \
    DEFAULT_GLOBAL_GIT_REPO_URL=https://github.com/projectsyn/getting-started-commodore-defaults \
    LIEUTENANT_DELETE_PROTECTION=false \
    SKIP_VAULT_SETUP=true

# tag::demo[]
echo "===> API deployment"
kubectl -n lieutenant apply -k "github.com/projectsyn/lieutenant-api/deploy?ref=v0.9.1"

echo "===> API configuration"
kubectl -n lieutenant set env deployment/lieutenant-api -c lieutenant-api \
  DEFAULT_API_SECRET_REF_NAME=gitlab-com

echo "===> For Minikube we must delete the default service and re-create it"
kubectl -n lieutenant delete svc lieutenant-api
kubectl -n lieutenant expose deployment lieutenant-api --type=NodePort --port=8080

echo "===> Launch ngrok in the background tunneling towards the Lieutenant API"
setsid ./ngrok.sh >/dev/null 2>&1 < /dev/null &
sleep 2s

echo "===> Find external Lieutenant URL through the ngrok API"
LIEUTENANT_URL=$(curl http://localhost:4040/api/tunnels --silent | jq -r '.["tunnels"][0]["public_url"]')
echo "===> Lieutenant API: $LIEUTENANT_URL"
# end::demo[]

wait_for_lieutenant "$LIEUTENANT_URL/healthz"

echo "===> Prepare Lieutenant Operator access to GitLab"
kubectl -n lieutenant create secret generic gitlab-com \
  --from-literal=endpoint="https://${GITLAB_ENDPOINT}" \
  --from-literal=hostKeys="$(ssh-keyscan $GITLAB_ENDPOINT)" \
  --from-literal=token="$GITLAB_TOKEN"

echo "===> Prepare Lieutenant API Authentication and Authorization"
kubectl -n lieutenant apply -f lib/auth.yaml

echo "===> Create Lieutenant Objects: Tenant and Cluster"
LIEUTENANT_TOKEN=$(kubectl -n lieutenant get secret "$(kubectl -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}')" -o go-template='{{.data.token | base64decode}}')
LIEUTENANT_AUTH="Authorization: Bearer ${LIEUTENANT_TOKEN}"

echo "===> Create a Lieutenant Tenant via the API"
TENANT_ID=$(curl -s -H "$LIEUTENANT_AUTH" -H "Content-Type: application/json" -X POST --data "{\"displayName\":\"Tutorial Tenant\",\"gitRepo\":{\"url\":\"ssh://git@${GITLAB_ENDPOINT}/${GITLAB_USERNAME}/tutorial-tenant.git\"},\"globalGitRepoRevision\":\"v1\"}" "${LIEUTENANT_URL}/tenants" | jq -r ".id")
echo "Tenant ID: $TENANT_ID"

echo "===> Patch the Tenant object to add a cluster template"
kubectl -n lieutenant patch tenant "$TENANT_ID" --type="merge" -p \
"{\"spec\":{\"clusterTemplate\": {
    \"gitRepoTemplate\": {
      \"apiSecretRef\":{\"name\":\"gitlab-com\"},
      \"path\":\"${GITLAB_USERNAME}\",
      \"repoName\":\"{{ .Name }}\"
    },
    \"tenantRef\":{}
}}}"

echo "===> Retrieve the registered Tenants via API and directly on the cluster"
curl -H "$LIEUTENANT_AUTH" "${LIEUTENANT_URL}/tenants"
kubectl -n lieutenant get tenant
kubectl -n lieutenant get gitrepo

echo "===> Register a Lieutenant Cluster via the API"
CLUSTER_ID=$(curl -s -H "$LIEUTENANT_AUTH" -H "Content-Type: application/json" -X POST --data "{ \"tenant\": \"${TENANT_ID}\", \"displayName\": \"Minikube cluster\", \"facts\": { \"cloud\": \"local\", \"distribution\": \"k3s\", \"region\": \"local\" }, \"gitRepo\": { \"url\": \"ssh://git@${GITLAB_ENDPOINT}/${GITLAB_USERNAME}/tutorial-cluster-minikube.git\" } }" "${LIEUTENANT_URL}/clusters" | jq -r ".id")
echo "Cluster ID: $CLUSTER_ID"

echo "===> Retrieve the registered Clusters via API and directly on the cluster"
curl -H "$LIEUTENANT_AUTH" "$LIEUTENANT_URL/clusters"
kubectl -n lieutenant get cluster
kubectl -n lieutenant get gitrepo

echo "===> LIEUTENANT API DONE"
