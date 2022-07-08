local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  route+: {
    '#': d.pkg(
      name='route',
      url='',
      help='Contains extensions to the default route functions provided by openshift-libsonnet',
    ),
    v1+: {
      route+: {
        '#new': d.fn('builds a route with a predefined host and TLS Edge termination',
                     [d.arg('name', d.T.string), d.arg('host', d.T.string), d.arg('path', d.T.string)]),
        new(name, host, path='/')::
          super.new(name)
          + super.spec.withHost(host)
          + super.spec.withPath(path)
          + super.spec.tls.withTermination('Edge')
          + super.spec.tls.withInsecureEdgeTerminationPolicy('Redirect'),
      },
    },
  },
}
