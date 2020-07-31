#!/usr/bin/env bash

trim () {
	local var="$*"
	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo -n "$var"
}

DOCKER_VERSION=$(docker version | grep Version -m 1)
DOCKER_VERSION=$(trim "$DOCKER_VERSION")
echo "Docker $DOCKER_VERSION"

PODMAN_VERSION=$(podman version | grep Version -m 1)
echo "Podman $PODMAN_VERSION"

MINIKUBE_VERSION=$(minikube version | grep version)
echo $MINIKUBE_VERSION

K3D_VERSION=$(k3d version | grep version -m 1)
echo $K3D_VERSION

VSCODE_PATH=$(which code)
echo "Visual Studio Code: $VSCODE_PATH"

CURL_PATH=$(which curl)
echo "curl: $CURL_PATH"

JQ_PATH=$(which jq)
echo "jq: $JQ_PATH"

YQ_PATH=$(which yq)
echo "yq: $YQ_PATH"

K9S_PATH=$(which k9s)
echo "k9s: $K9S_PATH"

SSH_KEYSCAN_PATH=$(which ssh-keyscan)
echo "ssh-keyscan: $SSH_KEYSCAN_PATH"

BASE64_PATH=$(which base64)
echo "base64: $BASE64_PATH"
