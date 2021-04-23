#!/usr/bin/env bash

COMMODORE_VERSION="v0.6.0"

commodore() {
  LIEUTENANT_URL=$(curl http://localhost:4040/api/tunnels --silent | jq -r '.["tunnels"][0]["public_url"]')
  LIEUTENANT_TOKEN=$(kubectl --context minikube --namespace lieutenant get secret "$(kubectl --context minikube --namespace lieutenant get sa api-access-synkickstart -o go-template='{{(index .secrets 0).name}}')" -o go-template='{{.data.token | base64decode}}')

  docker run \
    --interactive=true \
    --tty \
    --rm \
    --user="$(id -u)" \
    --env COMMODORE_API_URL="$LIEUTENANT_URL" \
    --env COMMODORE_API_TOKEN="$LIEUTENANT_TOKEN" \
    --env SSH_AUTH_SOCK=/tmp/ssh_agent.sock \
    --volume "${SSH_AUTH_SOCK}:/tmp/ssh_agent.sock" \
    --volume "${HOME}/.ssh/config:/app/.ssh/config:ro" \
    --volume "${HOME}/.ssh/known_hosts:/app/.ssh/known_hosts:ro" \
    --volume "${HOME}/.gitconfig:/app/.gitconfig:ro" \
    --volume "${PWD}:/app/data" \
    --workdir /app/data \
    projectsyn/commodore:${COMMODORE_VERSION:=latest} \
    $*
}

commodore_push_all() {
    CLUSTERS=($(kubectl --context minikube -n lieutenant get cluster -o jsonpath="{$.items[*].metadata.name}"))
    for CLUSTER in "${CLUSTERS[@]}"; do
        echo "===> Compiling and pushing catalog for cluster $CLUSTER"
        commodore catalog compile --push "$CLUSTER"
    done
}

commodore_compile_all() {
    CLUSTERS=($(kubectl --context minikube -n lieutenant get cluster -o jsonpath="{$.items[*].metadata.name}"))
    for CLUSTER in "${CLUSTERS[@]}"; do
        echo "===> Compiling and pushing catalog for cluster $CLUSTER"
        commodore catalog compile "$CLUSTER"
    done
}
