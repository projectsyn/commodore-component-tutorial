#!/usr/bin/env bash

check_variable () {
    if [ -z "$2" ]; then
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
        sleep 5
        RESULT=$($COMMAND)
    done
    echo "===> OK"
}

wait_for_token () {
    echo "===> Waiting for valid bootstrap token"
    EXPECTED="true"
    COMMAND="kubectl --context minikube -n lieutenant get cluster $1 -o jsonpath={.status.bootstrapToken.tokenValid}"
    RESULT=$($COMMAND)
    while [ "$RESULT" != "$EXPECTED" ]
    do
        echo "===> Not yet OK"
        sleep 10
        RESULT=$($COMMAND)
    done
    echo "===> Bootstrap token OK"
}
