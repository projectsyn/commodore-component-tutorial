#!/usr/bin/env bash

source ../lib/functions.sh
source ../lib/k3s.sh

# Wait for K3s to be ready
wait_for_k3s

echo "===> Find Tenant ID"
TENANT_ID=$(kubectl -n lieutenant get tenant | grep t- | awk 'NR==1{print $1}')
check_variable "TENANT_ID" $TENANT_ID

echo "===> Find Cluster ID"
CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')
check_variable "CLUSTER_ID" $CLUSTER_ID

echo "===> Removing everything"
kubectl -n lieutenant delete cluster "$CLUSTER_ID"
kubectl -n lieutenant delete tenant "$TENANT_ID"
k3d delete --name=projectsyn
