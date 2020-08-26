#!/usr/bin/env bash

source lib/functions.sh
source lib/minikube.sh

check_minikube
check_variable "GITLAB_ENDPOINT" $GITLAB_ENDPOINT
check_variable "GITLAB_USERNAME" $GITLAB_USERNAME

echo "===> Find Tenant ID"
TENANT_ID=$(kubectl --context minikube -n lieutenant get tenant | grep t- | awk 'NR==1{print $1}')
check_variable "TENANT_ID" $TENANT_ID

echo "===> Find Minikube Cluster ID"
MINIKUBE_CLUSTER_ID=$(kubectl --context minikube -n lieutenant get cluster | grep c- | grep Minikube | awk 'NR==1{print $1}')
check_variable "MINIKUBE_CLUSTER_ID" $MINIKUBE_CLUSTER_ID

echo "===> Find K3s Cluster ID"
K3S_CLUSTER_ID=$(kubectl --context minikube -n lieutenant get cluster | grep c- | grep K3s | awk 'NR==1{print $1}')
check_variable "K3S_CLUSTER_ID" $K3S_CLUSTER_ID

echo "===> Removing everything"
kubectl --context minikube -n lieutenant delete cluster "$K3S_CLUSTER_ID"
kubectl --context minikube -n lieutenant delete cluster "$MINIKUBE_CLUSTER_ID"
kubectl --context minikube -n lieutenant delete tenant "$TENANT_ID"

echo "===> Waiting 20 seconds for the removal of GitLab repositories"
sleep 20s

# minikube delete
# k3d cluster delete projectsyn
# killall ngrok
