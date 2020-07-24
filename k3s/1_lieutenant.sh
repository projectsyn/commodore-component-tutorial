#!/usr/bin/env bash

if [ -z "$GITLAB_TOKEN" ]; then
    echo "===> ERROR: GITLAB_TOKEN variable not set"
    exit 1
fi
echo "===> GITLAB_TOKEN: $GITLAB_TOKEN"

if [ -z "$GITLAB_ENDPOINT" ]; then
    echo "===> ERROR: No GITLAB_ENDPOINT found"
    exit 1
fi
echo "===> GITLAB_ENDPOINT: $GITLAB_ENDPOINT"

if [ -z "$GITLAB_USERNAME" ]; then
    echo "===> ERROR: GITLAB_USERNAME variable not set"
    exit 1
fi
echo "===> GITLAB_USERNAME: $GITLAB_USERNAME"

# K3s must be running
k3d create --name projectsyn

echo "===> Waiting for K3d to be up and running"
K3S_RUNNING=
while [ -z "$K3S_RUNNING" ]
do
    echo "===> K3s not yet ready"
    sleep 5s
    KUBECONFIG="$(k3d get-kubeconfig --name='projectsyn')"
    export KUBECONFIG
    K3S_RUNNING=$(kubectl get nodes | grep k3d)
done
echo "===> K3s running"
kubectl cluster-info

echo "===> Waiting for traefik service"
TRAEFIK=
while [ -z "$TRAEFIK" ]
do
    echo "===> Traefik not yet ready"
    sleep 5s
    TRAEFIK=$(kubectl get pod -n kube-system | grep traefik | grep Running | grep 1/1)
done
echo "===> Traefik ready"

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

echo "===> Ingress"
INGRESS_IP=
if [[ "$OSTYPE" == "darwin"* ]]; then
  INGRESS_IP=127.0.0.1
else
  INGRESS_IP=$(kubectl -n kube-system get svc traefik -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
fi
echo "===> Ingress: $INGRESS_IP"

kubectl -n lieutenant apply -f -<<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: lieutenant-api
spec:
  rules:
  - host: lieutenant.$INGRESS_IP.nip.io
    http:
      paths:
      - path: /
        backend:
          serviceName: lieutenant-api
          servicePort: 80
EOF

echo "===> Looping until the installation is ok"
EXPECTED="ok"
CURL=$(which curl)
COMMAND="$CURL --silent http://lieutenant.$INGRESS_IP.nip.io/healthz"
RESULT=$($COMMAND)
while [ "$RESULT" != "$EXPECTED" ]
do
    echo "===> Not yet OK"
    sleep 5s
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
LIEUTENANT_URL="lieutenant.${INGRESS_IP}.nip.io"
echo "===> Lieutenant URL: $LIEUTENANT_URL"

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
