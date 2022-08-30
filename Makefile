URL_FILES=$(wildcard */**/*.url)
MANIFESTS=$(URL_FILES:.url=.manifest.libsonnet)

%.manifest.libsonnet: %.url
	docker pull ghcr.io/cloudflightio/jsonnetify:main
	docker run --rm -it -v $(shell pwd)/:/work:z jsonnetify -i $(shell cat $<) -o /work/$@

.PHONY: fmt
fmt:
	tk fmt .

all: $(MANIFESTS) fmt
