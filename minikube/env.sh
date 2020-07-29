#!/usr/bin/env bash

source ../lib/minikube.sh

# Minikube must be running
check_minikube

export LIEUTENANT_URL=http://$(minikube service lieutenant-api -n lieutenant --url | sed 's/http:\/\///g' | awk '{split($0,a,":"); print "lieutenant." a[1] ".nip.io:" a[2]}')

export TENANT_ID=$(kubectl -n lieutenant get tenant | grep t- | awk 'NR==1{print $1}')

export CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')

export LIEUTENANT_TOKEN=$(kubectl -n lieutenant get secret $(kubectl -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')

echo "Lieutenant URL: $LIEUTENANT_URL"
echo "Lieutenant Token: $LIEUTENANT_TOKEN"
echo "Tenant ID: $TENANT_ID"
echo "Cluster ID: $CLUSTER_ID"

