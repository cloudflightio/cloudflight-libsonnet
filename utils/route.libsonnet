(import 'ksonnet-util/kausal.libsonnet') +
{
  local route = $.route.v1.route,
  utils+:: {
    routeFor(service,host,path="/")::
      route.new(service.metadata.name, host, path)
      + route.spec.to.withKind("Service")
      + route.spec.to.withName(service.metadata.name)
  }
}
