SHELL := /bin/bash # for 'source'

out_dir := ./build
docker_cmd  ?= docker
docker_opts ?= --rm --tty --user "$$(id -u)"
asciidoctor_pdf_cmd  ?= $(docker_cmd) run $(docker_opts) --volume "$${PWD}":/documents/ vshn/asciidoctor-pdf:1.4
asciidoctor_opts ?= --destination-dir=$(out_dir)

all: pdf

pdf: build/tutorial.pdf

.PHONY: build/tutorial.pdf
build/tutorial.pdf: tutorial.adoc
	$(asciidoctor_pdf_cmd) $(asciidoctor_opts) $<

clean:
	rm -rf build

setup:
	./0_requirements.sh; \
	./1_lieutenant_on_minikube.sh; \
	./2_commodore_on_minikube.sh; \
	./3_steward_on_minikube.sh; \
	source ./env.sh; \
	./4_synthesize_on_k3s.sh
