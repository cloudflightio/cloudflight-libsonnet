local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
(import "cloudflightLabels.libsonnet")
+ (import "route.libsonnet")
+ {
  extensions:: {
      '#': d.pkg(
        name='extensions',
        url='',
        help='Extensions available to the standard library',
      ),
  }
}
