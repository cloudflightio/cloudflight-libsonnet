(import 'cloudflight-libsonnet/infrastructure/grafana-agent/grafana-agent.libsonnet')
+ {
  _config+: {
    grafanaAgent+: {},
  },
} + {
  assert std.isObject($.grafanaAgent),
}
