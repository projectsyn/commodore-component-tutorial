#!/usr/bin/env bash

LIEUTENANT_URL=http://$(minikube service lieutenant-api -n lieutenant --url | sed 's/http:\/\///g' | awk '{split($0,a,":"); print "lieutenant." a[1] ".nip.io:" a[2]}')
export LIEUTENANT_URL

TENANT_ID=$(kubectl --context minikube --namespace lieutenant get tenant | grep t- | awk 'NR==1{print $1}')
export TENANT_ID

MINIKUBE_CLUSTER_ID=$(kubectl --context minikube --namespace lieutenant get cluster | grep c- | grep Minikube | awk 'NR==1{print $1}')
export MINIKUBE_CLUSTER_ID

K3S_CLUSTER_ID=$(kubectl --context minikube --namespace lieutenant get cluster | grep c- | grep K3s | awk 'NR==1{print $1}')
export K3S_CLUSTER_ID

LIEUTENANT_TOKEN=$(kubectl --context minikube --namespace lieutenant get secret $(kubectl --context minikube --namespace lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')
export LIEUTENANT_TOKEN

OPTION=$1

case "${OPTION}" in
    -docker)
        echo "# URL of Lieutenant API"
        echo "COMMODORE_API_URL=$LIEUTENANT_URL"
        echo "# Lieutenant API token"
        echo "COMMODORE_API_TOKEN=$LIEUTENANT_TOKEN"
        echo "# Base URL for global Git repositories"
        echo "COMMODORE_GLOBAL_GIT_BASE=ssh://git@github.com/$GITHUB_USERNAME"
        ;;
    *)
        echo "Lieutenant URL: $LIEUTENANT_URL"
        echo "Lieutenant Token: $LIEUTENANT_TOKEN"
        echo "Tenant ID: $TENANT_ID"
        echo "Minikube Cluster ID: $MINIKUBE_CLUSTER_ID"
        echo "K3s Cluster ID: $K3S_CLUSTER_ID"
        ;;
esac

