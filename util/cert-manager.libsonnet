local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  withK(k):: {
    '#certmanager': d.obj('certman holds functions related to cert-manager (cert-manager.io)'),
    certmanager+: {
      issuer+: {
        '#new': d.fn(|||
          constructs a cert-manager issuer resource for letsencrypt with sensible default.
        |||, [
          d.arg('emain', d.T.string),
          d.arg('ingressClassName', d.T.string, 'nginx'),
          d.arg('production', d.T.bool, true),
          d.arg('clusterwide', d.T.bool, true),
        ]),
        new(email, ingressClassName='nginx', production=true, clusterwide=true):: {
          local ci = self,

          local server = if production then 'https://acme-v02.api.letsencrypt.org/' else 'https://acme-staging-v02.api.letsencrypt.org/directory',
          local name = if production then 'letsencrypt-production' else 'letsencrypt-staging',

          apiVersion: 'cert-manager.io/v1',
          kind: if clusterwide then 'ClusterIssuer' else 'Issuer',
          metadata: {
            name: name,
          },
          spec+: {
            acme: {
              email: email,
              privateKeySecretRef: {
                name: name,
              },
              server: server,
              solvers: [
                {
                  http01: {
                    ingress: {
                      class: ingressClassName,
                    },
                  },
                },
              ],
            },
          },
        },
      },
    },
  },
}
