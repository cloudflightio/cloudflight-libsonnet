# Redis Cache Module

This module contains a Redis Cache, located in the `redis` key.

The following snippets lists all available configuration options alongside their default values:

```.ts
(import 'cloudflight-libsonnet/databases/redis.libsonnet')
+ {
  _config+: {
    {%
      include "../../../databases/redis.libsonnet"
      start="// begin_config\n"
      end="// end_config\n"
    %}
  }
}
```

## Starting multiple instances

Another way to use this module, is by calling the `newRedis` function. This
allows you to create multiple instances without polluting the global scope.

```.ts
{
  _config+:: {
    cacheOne: {
      name: 'cacheOne',
      password: 'foo',
    },
    cacheTwo: {
      name: 'cacheTwo',
      password: 'bar',
    }
  },
  cacheOne: (import 'cloudflight-libsonnet/databases/redis.libsonnet').newRedis($._config.cacheOne),
  cacheTwo: (import 'cloudflight-libsonnet/databases/redis.libsonnet').newRedis($._config.cacheTwo),
}
```

## High Availability

If required, you can instead import the `redis-sentinel` module. This creates an
additional sentinel deployment which fails over the master and replicas:

```.ts
(import 'cloudflight-libsonnet/databases/redis-sentinel.libsonnet')
+ {
  _config+: {
    {%
      include "../../../databases/redis-sentinel.libsonnet"
      start="// begin_config\n"
      end="// end_config\n"
    %}
  }
}
```


### Exposed values

When using `redis-sentinel`, you also have access to the following values. They are exposed, but not exported.

| Name                  | Contents                          |
|-----------------------|-----------------------------------|
| `redis.sentinelNodes` | Array of sentinel host:port pairs |
