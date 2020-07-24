#!/usr/bin/env bash

check_variable () {
    if [ -z $2 ]; then
        echo "===> ERROR: $1 variable not set"
        exit 1
    fi
    echo "===> $1: $2"
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
