#!/usr/bin/env bash

commodore_compile_all() {
    CLUSTERS=($(kubectl --context minikube -n lieutenant get cluster -o jsonpath="{$.items[*].metadata.name}"))
    for CLUSTER in "${CLUSTERS[@]}"; do
        echo "===> Compiling and pushing catalog for cluster $CLUSTER"
        commodore catalog compile --push "$CLUSTER"
    done
}
