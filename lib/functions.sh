#!/usr/bin/env bash

check_variable () {
    if [ -z $2 ]; then
        echo "===> ERROR: $1 variable not set"
        exit 1
    fi
    echo "===> OK: $1 variable set"
}

wait_for_lieutenant() {
    echo "===> Waiting for Lieutenant API: $1"
    EXPECTED="ok"
    CURL=$(which curl)
    COMMAND="$CURL --silent $1"
    RESULT=$($COMMAND)
    while [ "$RESULT" != "$EXPECTED" ]
    do
        echo "===> Not yet OK"
        sleep 5s
        RESULT=$($COMMAND)
    done
    echo "===> OK"
}

wait_for_argocd () {
    echo "===> Waiting for ArgoCD to be synced"
    EXPECTED="\"Synced\""
    COMMAND='kubectl -n syn get app root -o jsonpath="{.status.sync.status}"'
    RESULT=$($COMMAND)
    while [ "$RESULT" != "$EXPECTED" ]
    do
        echo "===> Not yet OK"
        sleep 10s
        RESULT=$($COMMAND)
    done
    echo "===> ArgoCD OK"
}
