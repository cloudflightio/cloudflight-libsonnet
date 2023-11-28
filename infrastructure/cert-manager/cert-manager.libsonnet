local manifest = (import './cert-manager.manifest.libsonnet');
local k = (import '../../prelude.libsonnet');

{
  _config+:: {
    // begin_config
    certmanager: {
      name: 'cert-manager',
      aks: false,
    },
    // end_config
  },

  newCertManager(config={}):: manifest {
    local this = self,
    local cfg = $._config.certmanager + config,

    'validatingwebhookconfiguration-cert-manager-webhook'+: if cfg.aks then {
      webhooks: [super.webhooks[0] {
        namespaceSelector+: {
          matchExpressions: super.matchExpressions + [
            { key: 'control-plane', operator: 'DoesNotExist' },
            { key: 'control-plane', operator: 'NotIn', values: ['true'] },
            { key: 'kubernetes.azure.com/managedby', operator: 'NotIn', values: ['aks'] },
          ],
        },
      }] + super.webhooks[1:],
    } else {},
  },

  certmanager: self.newCertManager(),
}
