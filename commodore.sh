#!/usr/bin/env bash

commodore () {
    docker run --env-file=.env --interactive=true --tty --rm --user="$(id -u)" --volume ~/.ssh:/app/.ssh:ro --volume "$PWD"/compiled/:/app/compiled/ --volume "$PWD"/catalog/:/app/catalog --volume "$PWD"/dependencies/:/app/dependencies/ --volume "$PWD"/inventory/:/app/inventory/ --volume ~/.gitconfig:/app/.gitconfig:ro projectsyn/commodore:v0.2.0 $*
}
