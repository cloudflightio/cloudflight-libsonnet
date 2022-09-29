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

If required, you can instead import the `redis-sentinel` module. This behaves
exactly like the redis module but will inject each container with a sentinel
node. This results in a highly available redis setup. The options available are:

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
