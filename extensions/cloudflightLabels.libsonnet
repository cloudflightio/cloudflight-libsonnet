local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
local k = import 'k.libsonnet';
{
  local appsExtentions = {
    deployment+: {
      new(name, replicas, containers, podLabels={})::
        super.new(name, replicas, containers, podLabels)
        + (if $._config.project != null then super.metadata.withLabels({
          'cloudflight.io/project': k._config.project,
        }) else {})
    },
  },
  apps+: {
    v1beta1+: appsExtentions,
    v1+: appsExtentions,
  },
  labeling:: {
    '#': d.pkg(
      name='labeling',
      url='',
      help=|||
        This extension allows you to label core kubernetes resources with useful labels.

        ## Usage

        To use this labeling function, edit your `k.libsonnet` to look something like this

        ```ts
        (import 'cloudflight-libsonnet/k.libsonnet')
        + {
          _config+:: {
            project: 'some-project-name'
          }
        }
        ```

        Afterwards, all resources created (provided they use
        `cloudflight-libsonnet/prelude.libsonnet`), will have the
        `cloudflight.io/project=some-project-name` label attached

        If you need to set this on a per-environment basis, move the
        `k.libsonnet` file to your environment folder as described [in the Tanka
        documentation](https://tanka.dev/libraries/import-paths).

      |||,
    ),
  }
}
