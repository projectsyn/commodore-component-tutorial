#!/usr/bin/env bash

echo "===> Find private SSH key location"
if [ -z "$COMMODORE_SSH_PRIVATE_KEY" ]; then
    echo "===> ERROR: No COMMODORE_SSH_PRIVATE_KEY found"
    exit 1
fi
echo "===> COMMODORE_SSH_PRIVATE_KEY: $COMMODORE_SSH_PRIVATE_KEY"

echo "===> Find GitLab endpoint"
if [ -z "$GITLAB_ENDPOINT" ]; then
    echo "===> ERROR: No GITLAB_ENDPOINT found"
    exit 1
fi
echo "===> GITLAB_ENDPOINT: $GITLAB_ENDPOINT"

echo "===> Waiting for K3d to be up and running"
KUBECONFIG="$(k3d get-kubeconfig --name='projectsyn')"
export KUBECONFIG
K3S_RUNNING=$(kubectl get nodes | grep k3d)
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
TRAEFIK=$(kubectl get pod -n kube-system | grep traefik | grep 1/1)
while [ -z "$TRAEFIK" ]
do
    echo "===> Traefik not yet ready"
    sleep 5s
    TRAEFIK=$(kubectl get pod -n kube-system | grep traefik | grep Running | grep 1/1)
done
echo "===> Traefik ready"

echo "===> Find Lieutenant URL"

INGRESS_IP=
if [[ "$OSTYPE" == "darwin"* ]]; then
  INGRESS_IP=127.0.0.1
else
  INGRESS_IP=$(kubectl -n kube-system get svc traefik -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
fi
echo "===> Ingress: $INGRESS_IP"

LIEUTENANT_URL="http://lieutenant.${INGRESS_IP}.nip.io/"
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
