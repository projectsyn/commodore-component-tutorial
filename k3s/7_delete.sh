#!/usr/bin/env bash

source ../lib/functions.sh
source ../lib/k3s.sh

# Wait for K3s to be ready
wait_for_k3s

check_variable "TENANT_ID" $TENANT_ID
check_variable "CLUSTER_ID" $CLUSTER_ID

echo "===> Removing everything"
kubectl -n lieutenant delete cluster "$CLUSTER_ID"
kubectl -n lieutenant delete tenant "$TENANT_ID"
k3d delete --name=projectsyn
