local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  networking+: {
    '#': d.pkg(
      name='networking',
      url='',
      help='Contains extensions related to cert-manager',
    ),
    v1+: {
      ingress+: {
        local annotation_prefix = { call(clusterwide):: if clusterwide then 'cert-manager.io/cluster-issuer' else 'cert-manager.io/issuer' },
        '#withCertMixin': d.fn(|||
          withCertMixin instructs cert-manager to add an certificate to the ingress-resource.
        |||, [
          d.arg('issuer', d.T.string),
          d.arg('clusterwide', d.T.bool),
        ]),
        withCertMixin(issuer, clusterwide=true)::
          super.metadata.withAnnotationsMixin({
            [annotation_prefix.call(clusterwide)]: (if std.type(issuer) == 'object' then issuer.metadata.name else issuer),
          }),
      },
    },
  },
}
