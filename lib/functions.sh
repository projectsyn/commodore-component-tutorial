#!/usr/bin/env bash

check_variable () {
    if [ -z $2 ]; then
        echo "===> ERROR: $1 variable not set"
        exit 1
    fi
    echo "===> $1: $2"
}
