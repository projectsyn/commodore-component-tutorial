#!/usr/bin/env bash

source ../lib/functions.sh
source ../lib/minikube.sh

check_minikube

echo "===> Find Tenant ID"
TENANT_ID=$(kubectl -n lieutenant get tenant | grep t- | awk 'NR==1{print $1}')
check_variable "TENANT_ID" $TENANT_ID

echo "===> Find Cluster ID"
CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')
check_variable "CLUSTER_ID" $CLUSTER_ID

echo "===> Removing everything"
kubectl -n lieutenant delete cluster "$CLUSTER_ID"
kubectl -n lieutenant delete tenant "$TENANT_ID"
minikube delete
