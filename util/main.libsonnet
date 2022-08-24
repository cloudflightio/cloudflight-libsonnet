local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  withK(k)::
    (import 'java.libsonnet').withK(k)
    + (import 'route.libsonnet').withK(k)
    + (import 'service.libsonnet').withK(k)
    + (import 'cert-manager.libsonnet').withK(k)
    + (import 'openshift-oauth.libsonnet').withK(k)
    + {
      '#': d.pkg(
        name='util',
        url='',
        help='The util package contains ease of use functions to simplify working with kubernetes and jsonnet',
      ),
    },
}
