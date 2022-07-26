local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  withK(k):: {
    local service = k.core.v1.service,
    '#serviceFor': d.fn(|||

      serviceFor constructs a service for the specified deployment.

      Selector labels are taken from the pod spec but can be ignored using the
      `ignored_labels` parameter.

      The ports of the service will have the same name as in the container spec
      to avoid confusion. This can be changed with the `nameFormat` parameter.
    |||, [
      d.arg('deployment', d.T.object),
      d.arg('ignored_labels', d.T.array),
      d.arg('nameFormat', d.T.string, '%(port)s'),
    ]),
    serviceFor(deployment, ignored_labels=[], nameFormat='%(port)s')::
      super.serviceFor(deployment, ignored_labels, nameFormat)
      + service.metadata.withLabelsMixin(
        if (std.objectHas(deployment.metadata, 'labels')) then deployment.metadata.labels else {},
      ),
  },
}
