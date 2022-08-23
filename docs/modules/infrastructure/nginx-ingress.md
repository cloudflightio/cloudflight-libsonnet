# Nginx-Ingress Module

This adds nginx-ingress-controller (see https://github.com/kubernetes/ingress-nginx), located in the `nginxingress` key.

This is helpful if no other ingress-controller is deployes (e.g. AKS without API Gateway). 

The following snippets lists all available configuration options alongside their default values:

```.ts
(import 'cloudflight-libsonnet/infrastructure/nginx-ingress/nginx-ingress.libsonnet')
+ {
  _config+: {
    {%
      include "../../../infrastructure/nginx-ingress/nginx-ingress.libsonnet"
      start="// begin_config\n"
      end="// end_config\n"
    %}
  }
}
```
