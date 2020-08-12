#!/usr/bin/env bash

LOCAL_LIEUTENANT_URL=$(minikube service lieutenant-api -n lieutenant --url)
ngrok http $LOCAL_LIEUTENANT_URL
