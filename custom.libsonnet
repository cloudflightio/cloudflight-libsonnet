local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
(import 'extensions/main.libsonnet')
+ {
  '#': d.pkg(
    name='cloudflight-libsonnet',
    url='',
    help=|||
      This library contains various utility modules for use with the jsonnet configuration language
      To get started, import the provided prelude which will composit the library for you.

      ```ts
      local k = import ('cloudflight-libsonnet/prelude.libsonnet');
      ```

      The prelude depends on a file called `k.libsonnet` being available for
      import. Either place it in your lib or environment folder. Using the
      environment folder allows for library level configuration options to be
      applied on an environment level.

      This works, because import paths are ranked as highlighted [in the Tanka
      documentation](https://tanka.dev/libraries/import-paths).

      A pre-populated `k.libsonnet` is available in this library so a minimal
      `k.libsonnet` would look like this:

      ```ts
      (import 'cloudflight-libsonnet/k.libsonnet')
      ```

      This includes
      [k8s-libsonnet](https://jsonnet-libs.github.io/k8s-libsonnet/),
      [openshift-libsonnet](https://jsonnet-libs.github.io/openshift-libsonnet/)
      as well as
      [prometheus-libsonnet](https://jsonnet-libs.github.io/kube-prometheus-libsonnet/)

      For more information on customization options in `k.libsonnet`, take a
      look at the [labeling](labeling/) extension.

    |||, ), util+:
    (import 'util/main.libsonnet').withK(self), }
