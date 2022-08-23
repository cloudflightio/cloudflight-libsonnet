VERSION = $(shell cat version.txt)

cert-manager.manifest.libsonnet: version.txt cert-manager.libsonnet
	touch cert-manager.manifest.libsonnet
	docker pull ghcr.io/cloudflightio/jsonnetify:main
	docker run --rm -it -v $(shell pwd)/cert-manager.manifest.libsonnet:/work/manifest.libsonnet:z ghcr.io/cloudflightio/jsonnetify:main https://github.com/cert-manager/cert-manager/releases/download/v$(VERSION)/cert-manager.yaml
