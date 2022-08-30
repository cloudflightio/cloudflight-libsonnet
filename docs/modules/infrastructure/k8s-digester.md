# k8s-digester Module

This module installs the [k8s-digester](https://github.com/google/k8s-digester)
in your cluster. It currently does not offer any customization options and is
functionally equivalent to applying the `digester_manifest.yaml`.

The reason for this module is to have everything you need in one place without
relying on manual `kubectl apply` steps.
