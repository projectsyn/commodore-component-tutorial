#!/usr/bin/env bash

commodore () {
    docker run \
    --env-file=.env \
    --interactive=true \
    --tty \
    --rm \
    --user="$(id -u)" \
    --volume "$HOME"/.ssh:/app/.ssh:ro \
    --volume "$PWD"/compiled/:/app/compiled/ \
    --volume "$PWD"/catalog/:/app/catalog \
    --volume "$PWD"/dependencies/:/app/dependencies/ \
    --volume "$PWD"/inventory/:/app/inventory/ \
    --volume ~/.gitconfig:/app/.gitconfig:ro \
    projectsyn/commodore:v0.2.0 \
    $*
}

commodore_compile_all() {
    CLUSTERS=($(kubectl --context minikube -n lieutenant get cluster -o jsonpath="{$.items[*].metadata.name}"))
    for CLUSTER in "${CLUSTERS[@]}"; do
        commodore catalog compile --push "$CLUSTER"
    done
}
