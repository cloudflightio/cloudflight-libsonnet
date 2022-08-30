local manifest = (import './k8s-digester.manifest.libsonnet');
local k = (import '../../prelude.libsonnet');

{
  new():: manifest,

  k8sDigester: self.new(),
}
