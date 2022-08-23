# Cert-Manager Module

This adds certmanager (see https://cert-manager.io/), located in the `certmanager` key.

It helpes you issuing and managing certificated using custom k8s resources only. 

The following snippets lists all available configuration options alongside their default values:

```.ts
(import 'cloudflight-libsonnet/infrastructure/cert-manager/cert-manager.libsonnet')
+ {
  _config+: {
    {%
      include "../../../infrastructure/cert-manager/cert-manager.libsonnet"
      start="// begin_config\n"
      end="// end_config\n"
    %}
  }
}
```

## Example

```.ts
{%
    include "../../../tests/environments/test-infrastructure-cert-manager/main.jsonnet"
    end="} + {"
%}}
```

## Addons

There is also a special set of utilities and extensions that can be used to make the setup process easier.

This example installs cert-manager, adds a lets-encrypt issuer and a ssl-protected ingress-rule:

```.ts
local k = (import 'k.libsonnet');
{%
    include "../../../tests/environments/test-extensions-cert-manager/main.jsonnet"
    start="local k = (import '../../../prelude.libsonnet');\n"
%}
```
