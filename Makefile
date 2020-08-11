out_dir := ./build
docker_cmd  ?= docker
docker_opts ?= --rm --tty --user "$$(id -u)"
asciidoctor_cmd  ?= $(docker_cmd) run $(docker_opts) --volume "$${PWD}":/documents/ asciidoctor/docker-asciidoctor asciidoctor
asciidoctor_pdf_cmd  ?= $(docker_cmd) run $(docker_opts) --volume "$${PWD}":/documents/ vshn/asciidoctor-pdf:1.4
asciidoctor_opts ?= --destination-dir=$(out_dir)

all: pdf

pdf: build/tutorial.pdf

build/tutorial.pdf: tutorial.adoc
	$(asciidoctor_pdf_cmd) $(asciidoctor_opts) $<

clean:
	rm -rf build
