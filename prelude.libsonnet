(import 'ksonnet-util/kausal.libsonnet') +
{
  local appsExtentions = {
    deployment+: {
      new(name, replicas, containers, podLabels={})::
        super.new(name, replicas, containers, podLabels)
        + super.metadata.withLabels({
          'cloudflight.io/project': $.project,
        })
    },
  },
  apps+: {
    v1beta1+: appsExtentions,
    v1+: appsExtentions,
  },
}
