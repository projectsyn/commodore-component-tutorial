#!/usr/bin/env bash

export LIEUTENANT_URL=http://$(minikube service lieutenant-api -n lieutenant --url | sed 's/http:\/\///g' | awk '{split($0,a,":"); print "lieutenant." a[1] ".nip.io:" a[2]}')

export CLUSTER_ID=$(kubectl -n lieutenant get cluster | grep c- | awk 'NR==1{print $1}')

export LIEUTENANT_TOKEN=$(kubectl -n lieutenant get secret $(kubectl -n lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}') -o go-template='{{.data.token | base64decode}}')

