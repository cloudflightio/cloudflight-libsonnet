local cm = import 'github.com/jsonnet-libs/cert-manager-libsonnet/1.8/main.libsonnet';
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
          d.arg('name', d.T.string, 'letsencrypt-production || letsencrypt-staging'),
        ]),
        new(
          email,
          ingressClassName='nginx',
          production=true,
          clusterwide=true,
          name=(if production then 'letsencrypt-production' else 'letsencrypt-staging')
        )::
          (if clusterwide then cm.nogroup.v1.clusterIssuer.new(name) else cm.nogroup.v1.issuer.new(name))
          + cm.nogroup.v1.issuer.spec.acme.withEmail(email)
          + cm.nogroup.v1.issuer.spec.acme.withServer(
            if production then 'https://acme-v02.api.letsencrypt.org/' else 'https://acme-staging-v02.api.letsencrypt.org/directory'
          )
          + cm.nogroup.v1.issuer.spec.acme.privateKeySecretRef.withName(name)
          + cm.nogroup.v1.issuer.spec.acme.withSolvers([
            cm.nogroup.v1.issuer.spec.acme.solvers.http01.ingress.withClass(ingressClassName),
          ])
      },
    },
  },
}
