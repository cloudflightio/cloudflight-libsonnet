local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  withK(k):: {
    local route = k.route.v1.route,
    '#routeFor': d.fn(|||
      routeFor constructs a openshift route to the specified service. It expects
      a value for the hostname and defaults to '/' for the path.
    |||, [d.arg('port', d.T.number, 18080), d.arg('path', d.T.string, '/actuator/health')]),
    routeFor(service, host, path='/')::
      route.new(service.metadata.name, host, path)
      + route.spec.to.withKind('Service')
      + route.spec.to.withName(service.metadata.name),
  },
}
