#!/usr/bin/env bash

K3S_RUNNING=$(kubectl get nodes | grep k3d)
if [ -z "$K3S_RUNNING" ]; then
    echo "===> ERROR: K3s is not running"
    exit 1
fi
echo "===> K3s running"

echo "===> Find Tenant ID"
TENANT_ID=$(kubectl -n lieutenant get tenant | grep t- | awk 'NR==1{print $1}')
if [ -z "$TENANT_ID" ]; then
    echo "===> ERROR: No TENANT_ID found"
    exit 1
fi
echo "===> TENANT_ID: $TENANT_ID"

echo "===> Find Cluster ID"
CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')
if [ -z "$CLUSTER_ID" ]; then
    echo "===> ERROR: No CLUSTER_ID found"
    exit 1
fi
echo "===> CLUSTER_ID: $CLUSTER_ID"

echo "===> Removing everything"
kubectl -n lieutenant delete cluster "$CLUSTER_ID"
kubectl -n lieutenant delete tenant "$TENANT_ID"
k3d delete --name=projectsyn
