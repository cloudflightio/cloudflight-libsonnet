local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  withK(k):: {
    '#openshiftOAuth': d.obj('openshiftOAuth contains utilities to proxy an application using the [OpenShift OAuth Proxy](https://github.com/openshift/oauth-proxy)'),
    openshiftOAuth+: {
      local root = self,
      serviceAccount+: {
        '#new': d.fn(|||
          constructs a serviceaccount annotated with a oauth-redirectreference
          pointing to the route parameter
        |||, [d.arg('name', d.T.string), d.arg('route', d.T.string)]),
        new(name, route): k.core.v1.serviceAccount.new(name)
                          + k.core.v1.serviceAccount.metadata.withAnnotationsMixin({
                            'serviceaccounts.openshift.io/oauth-redirectreference.primary': |||
                              {"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"%(name)s"}}
                            ||| % { name: if std.isObject(route) then route.metadata.name else route },
                          }),
      },
      container+: {
        local container = k.core.v1.container,
        '#new': d.fn(|||
          constructs a container proxying connections to the `upstream` parameter.
        |||, [d.arg('upstream', d.T.string), d.arg('serviceAccount', d.T.string)]),
        new(upstream, serviceAccount): container.new('proxy', 'quay.io/openshift/origin-oauth-proxy:4.10')
                                       + container.withArgs([
                                         '--http-address=:4180',
                                         '--https-address=',
                                         '--upstream=' + upstream,
                                         '--cookie-secret-file=/var/run/secrets/kubernetes.io/serviceaccount/token',
                                         '--provider=openshift',
                                         '--openshift-service-account=' + (if std.isObject(serviceAccount) then serviceAccount.metadata.name else serviceAccount),
                                       ])
                                       + container.withPorts([
                                         k.core.v1.containerPort.newNamed(4180, 'http'),
                                       ]),
      },
      deployment+: {
        '#withProxy': d.fn(|||
          add a proxy sidecar to the container. This also sets the service
          account used by the pod. The ServiceAccount needs to have the correct
          redirect reference for the route. See
          `openshiftOAuth.serviceAccount.new` for an easy way to create a
          compliant service account
        |||, [d.arg('upstream', d.T.string), d.arg('serviceAccount', d.T.string)]),
        withProxy(upstream, serviceAccount)::
          k.apps.v1.deployment.spec.template.spec.withServiceAccountName(if std.isObject(serviceAccount) then serviceAccount.metadata.name else serviceAccount)
          + k.apps.v1.deployment.spec.template.spec.withContainersMixin(root.container.new(upstream, serviceAccount)),
      },
    },
  },
}
