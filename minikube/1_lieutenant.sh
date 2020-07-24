#!/usr/bin/env bash

source ../lib/functions.sh

check_variable "GITLAB_TOKEN" $GITLAB_TOKEN
check_variable "GITLAB_ENDPOINT" $GITLAB_ENDPOINT
check_variable "GITLAB_USERNAME" $GITLAB_USERNAME

# Minikube must be running
minikube start
MINIKUBE_RUNNING=$(kubectl get nodes | grep minikube)
if [ -z "$MINIKUBE_RUNNING" ]; then
    echo "===> ERROR: Minikube is not running"
    exit 1
fi
echo "===> Minikube running"

echo "===> Creating namespace"
kubectl create namespace lieutenant

echo "===> CRDs (global scope)"
kubectl apply -k github.com/projectsyn/lieutenant-operator/deploy/crds

echo "===> Operator deployment"
kubectl -n lieutenant apply -k github.com/projectsyn/lieutenant-operator/deploy

echo "===> Operator configuration"
kubectl -n lieutenant set env deployment/lieutenant-operator -c lieutenant-operator \
    SKIP_VAULT_SETUP=true \
    DEFAULT_DELETION_POLICY=Delete \
    LIEUTENANT_DELETE_PROTECTION=false

echo "===> API deployment"
kubectl -n lieutenant apply -k "github.com/projectsyn/lieutenant-api/deploy?ref=v0.2.0"

echo "===> For Minikube we must delete the default service and re-create it"
kubectl -n lieutenant delete svc lieutenant-api
kubectl -n lieutenant expose deployment lieutenant-api --type=NodePort --port=8080

echo "===> Find Lieutenant URL"
LIEUTENANT_URL=$(minikube service lieutenant-api -n lieutenant --url | sed 's/http:\/\///g' | awk '{split($0,a,":"); print "lieutenant." a[1] ".nip.io:" a[2]}')

echo "===> Lieutenant API: $LIEUTENANT_URL"

echo "===> Looping until the installation is ok"
EXPECTED="ok"
CURL=$(which curl)
COMMAND="$CURL --silent $LIEUTENANT_URL/healthz"
RESULT=$($COMMAND)
while [ "$RESULT" != "$EXPECTED" ]
do
    echo "===> Not yet OK"
    sleep 1s
    RESULT=$($COMMAND)
done
echo "===> OK"

echo "===> Prepare Lieutenant Operator access to GitLab"
kubectl -n lieutenant create secret generic vshn-gitlab \
  --from-literal=endpoint="https://gitlab.com" \
  --from-literal=hostKeys="$(ssh-keyscan gitlab.com)" \
  --from-literal=token="$GITLAB_TOKEN"

echo "===> Prepare Lieutenant API Authentication and Authorization"
kubectl -n lieutenant apply -f -<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: lieutenant-api-user
rules:
- apiGroups:
  - syn.tools
  resources:
  - clusters
  - clusters/status
  - tenants
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: lieutenant-api-user
roleRef:
  kind: Role
  name: lieutenant-api-user
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: api-access-synkickstart
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-access-synkickstart
EOF

echo "===> Create Lieutenant Objects: Tenant and Cluster"
LIEUTENANT_TOKEN=$(kubectl -n lieutenant get secret $(kubectl -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')
LIEUTENANT_AUTH="Authorization: Bearer ${LIEUTENANT_TOKEN}"

echo "===> Create a Lieutenant Tenant via the API"
TENANT_ID=$(curl -s -H "$LIEUTENANT_AUTH" -H "Content-Type: application/json" -X POST --data "{\"displayName\":\"My first Tenant\",\"gitRepo\":{\"url\":\"ssh://git@${GITLAB_ENDPOINT}/${GITLAB_USERNAME}/mytenant.git\"}}" "${LIEUTENANT_URL}/tenants" | jq -r ".id")
echo "Tenant ID: $TENANT_ID"

echo "===> Retrieve the registered Tenants via API and directly on the cluster"
curl -H "$LIEUTENANT_AUTH" "${LIEUTENANT_URL}/tenants"
kubectl -n lieutenant get tenant
kubectl -n lieutenant get gitrepo

echo "===> Register a Lieutenant Cluster via the API"
CLUSTER_ID=$(curl -s -H "$LIEUTENANT_AUTH" -H "Content-Type: application/json" -X POST --data "{ \"tenant\": \"${TENANT_ID}\", \"displayName\": \"My first Project Syn cluster\", \"facts\": { \"cloud\": \"local\", \"distribution\": \"k3s\", \"region\": \"local\" }, \"gitRepo\": { \"url\": \"ssh://git@${GITLAB_ENDPOINT}/${GITLAB_USERNAME}/cluster-gitops1.git\" } }" "http://${LIEUTENANT_URL}/clusters" | jq -r ".id")
echo "Cluster ID: $CLUSTER_ID"

echo "===> Retrieve the registered Clusters via API and directly on the cluster"
curl -H "$LIEUTENANT_AUTH" "$LIEUTENANT_URL/clusters"
kubectl -n lieutenant get cluster
kubectl -n lieutenant get gitrepo

echo "===> LIEUTENANT API DONE"
