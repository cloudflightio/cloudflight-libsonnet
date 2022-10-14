(import 'cloudflight-libsonnet/databases/redis-sentinel.libsonnet')
{
  _config+:: {
    redis+: {
      password: 'foobar',
      storage: '1Gi',
    },
  },
}
