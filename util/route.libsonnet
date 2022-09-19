local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  withK(k):: {
    local route = k.route.v1.route,
    '#routeFor': d.fn(|||
      routeFor constructs a openshift route to the specified service. It expects
      a value for the hostname and defaults to '/' for the path.
    |||, [
      d.arg('service', d.T.object),
      d.arg('host', d.T.string, ''),
      d.arg('path', d.T.string, '/'),
      d.arg('port', d.T.number, 'service.spec.ports[0].port'),
    ]),
    routeFor(service, host, path='/', port=service.spec.ports[0].port)::
      route.new(service.metadata.name, host, path)
      + route.spec.to.withKind('Service')
      + route.spec.to.withName(service.metadata.name)
      + route.spec.port.withTargetPort(port),

    '#weightedRouteFor': d.fn(|||
      weightedRouteFor constructs a openshift route to the specified services. It expects
      a value for the name, hostname, port, services and defaults to '/' for the path.
      services expects an array consisting of objects with the keys name (name of the service) and weight.
    |||, [
      d.arg('name', d.T.string),
      d.arg('host', d.T.string, ''),
      d.arg('port', d.T.number, ''),
      d.arg('services', d.T.object),
      d.arg('path', d.T.string, '/'),
    ]),
    weightedRouteFor(name, host, port, services, path='/')::
      route.new(name, host, path)
      + route.spec.to.withKind('Service')
      + route.spec.to.withName(services[0].name)
      + route.spec.to.withWeight(services[0].weight)
      + route.spec.port.withTargetPort(port)
      + route.spec.withAlternateBackends(
        std.map(function(v) v { kind: 'Service' }, services)[1:std.length(services):1]
      ),

    local ingress = k.networking.v1.ingress,
    local rule = k.networking.v1.ingressRule,
    local hpath = k.networking.v1.httpIngressPath,
    '#ingressFor': d.fn(|||
      ingressFor constructs a ingress object, compatible with the automatic
      translation to openshift routes. It expects a value for the hostname and
      defaults to '/' for the path.
    |||, [
      d.arg('service', d.T.object),
      d.arg('host', d.T.string, ''),
      d.arg('path', d.T.string, '/'),
      d.arg('port', d.T.number, 'service.spec.ports[0].port'),
    ]),
    ingressFor(service, host, path='/', port=service.spec.ports[0].port)::
      ingress.new(service.metadata.name)
      + ingress.metadata.withAnnotationsMixin({
        'route.openshift.io/termination': 'edge',
      })
      + ingress.spec.withRules(
        rule.withHost(host)
        + rule.http.withPaths([
          hpath.withPath(path)
          + hpath.withPathType('Prefix')
          + hpath.backend.service.withName(service.metadata.name)
          + hpath.backend.service.port.withNumber(port),
        ])
      ),

  },
}
