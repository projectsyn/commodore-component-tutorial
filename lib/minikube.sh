#!/usr/bin/env bash

check_minikube() {
    MINIKUBE_RUNNING=$(kubectl get nodes | grep minikube)
    if [ -z "$MINIKUBE_RUNNING" ]; then
        echo "===> ERROR: Minikube is not running"
        exit 1
    fi
    echo "===> Minikube running"
}
