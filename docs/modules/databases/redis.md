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
