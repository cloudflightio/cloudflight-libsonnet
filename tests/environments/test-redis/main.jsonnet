{
  _config+:: {
    cacheOne: {
      name: 'cacheOne',
      password: 'foo',
    },
    cacheTwo: {
      name: 'cacheTwo',
      password: 'bar',
    },
  },
  cacheOne: (import 'cloudflight-libsonnet/databases/redis.libsonnet').newRedis($._config.cacheOne),
  cacheTwo: (import 'cloudflight-libsonnet/databases/redis.libsonnet').newRedis($._config.cacheTwo),
}
