out_dir := ./build
docker_cmd  ?= docker
docker_opts ?= --rm --tty --user "$$(id -u)"
asciidoctor_pdf_cmd  ?= $(docker_cmd) run $(docker_opts) --volume "$${PWD}":/documents/ vshn/asciidoctor-pdf:1.6.0
asciidoctor_opts ?= --destination-dir=$(out_dir)

.PHONY: all
all: pdf

.PHONY: pdf
pdf: build/tutorial.pdf

build/tutorial.pdf: docs/tutorial.adoc
	$(asciidoctor_pdf_cmd) $(asciidoctor_opts) $<

.PHONY: clean
clean:
	rm -rf build

.PHONY: setup
setup:
	./0_requirements.sh; \
	./1_lieutenant_on_minikube.sh; \
	./2_commodore_on_minikube.sh; \
	./3_steward_on_minikube.sh; \
	./4_synthesize_on_k3s.sh
