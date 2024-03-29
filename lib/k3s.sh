#!/usr/bin/env bash

wait_for_k3s () {
    echo "===> Waiting for K3d to be up and running"
    K3S_RUNNING=$(kubectl --context k3d-projectsyn get nodes | grep k3d)
    while [ -z "$K3S_RUNNING" ]
    do
        echo "===> K3s not yet ready"
        sleep 5
        K3S_RUNNING=$(kubectl get nodes | grep k3d)
    done
    echo "===> K3s running"
    kubectl cluster-info
}

wait_for_traefik () {
    echo "===> Waiting for traefik service"
    TRAEFIK=$(kubectl --context k3d-projectsyn get pod -n kube-system | grep traefik | grep 1/1)
    while [ -z "$TRAEFIK" ]
    do
        echo "===> Traefik not yet ready"
        sleep 5
        TRAEFIK=$(kubectl --context k3d-projectsyn get pod -n kube-system | grep traefik | grep Running | grep 1/1)
    done
    echo "===> Traefik ready"
}

set_ingress_ip () {
    INGRESS_IP=
    if [[ "$OSTYPE" == "darwin"* ]]; then
        INGRESS_IP=127.0.0.1
    else
        INGRESS_IP=$(kubectl --context k3d-projectsyn -n kube-system get svc traefik -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    fi
    echo "===> Ingress: $INGRESS_IP"
}
