local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  core+: {
    '#': d.pkg(
      name='core',
      url='',
      help='Contains extensions related to core kubernetes components',
    ),
    v1+: {
      container+: {
        '#new': d.fn('new returns a new container of given name and image. By default it injects an openshift 4.11 compatible securityContext',
                     [d.arg('name', d.T.string), d.arg('image', d.T.string), d.arg('unprivileged', d.T.string, 'true')]),
        new(name, image, unprivileged=true)::
          super.new(name, image)
          + if unprivileged then (
            self.securityContext.withAllowPrivilegeEscalation(false)
            + self.securityContext.capabilities.withDrop(['ALL'])
            + self.securityContext.withRunAsNonRoot(true)
            + self.securityContext.seccompProfile.withType('RuntimeDefault')
          ) else {},
      },
    },
  },
}
