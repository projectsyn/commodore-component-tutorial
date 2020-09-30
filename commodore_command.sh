#!/usr/bin/env bash

commodore () {
    docker run \
    --env-file=.env \
    --interactive=true \
    --tty \
    --rm \
    --user="$(id -u)" \
    --volume "$HOME"/.ssh:/app/.ssh:ro \
    --volume ~/.gitconfig:/app/.gitconfig:ro \
    --volume "${PWD}:/app/data/" \
    --workdir "/app/data" \
    projectsyn/commodore:v0.2.0 \
    $*
}

commodore_compile_all() {
    CLUSTERS=($(kubectl --context minikube -n lieutenant get cluster -o jsonpath="{$.items[*].metadata.name}"))
    for CLUSTER in "${CLUSTERS[@]}"; do
        echo "===> Compiling and pushing catalog for cluster $CLUSTER"
        commodore catalog compile --push "$CLUSTER"
    done
}
