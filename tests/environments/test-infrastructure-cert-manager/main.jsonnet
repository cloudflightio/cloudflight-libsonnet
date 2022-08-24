(import 'cloudflight-libsonnet/infrastructure/cert-manager/cert-manager.libsonnet')
+ {
  _config+: {
    certmanager: {
      name: 'cert-manager',
      namespace: 'cert-manager',
      aks: true,
    },
  },
} + {
  assert std.isObject($.certmanager),
}
