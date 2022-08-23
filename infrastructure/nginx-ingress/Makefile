VERSION = $(shell cat version.txt)

nginx-ingress.manifest.libsonnet: version.txt nginx-ingress.libsonnet
	touch nginx-ingress.manifest.libsonnet
	docker pull ghcr.io/cloudflightio/jsonnetify:main
	docker run --rm -it -v $(shell pwd)/nginx-ingress.manifest.libsonnet:/work/manifest.libsonnet:z ghcr.io/cloudflightio/jsonnetify:main https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v$(VERSION)/deploy/static/provider/cloud/deploy.yaml 
