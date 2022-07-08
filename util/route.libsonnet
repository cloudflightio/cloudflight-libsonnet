{
  withK(k):: {
    local route = k.route.v1.route,
    routeFor(service,host,path="/")::
      route.new(service.metadata.name, host, path)
      + route.spec.to.withKind("Service")
      + route.spec.to.withName(service.metadata.name)
  }
}
