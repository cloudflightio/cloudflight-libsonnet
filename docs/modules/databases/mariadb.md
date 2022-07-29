# MariaDB Database Module

This module contains a MariaDB instance, located in the `mariadb` key.

The following snippets lists all available configuration options alongside their default values:

```.ts
(import 'cloudflight-libsonnet/databases/mariadb.libsonnet')
+ {
  _config+: {
    {%
      include "../../../databases/mariadb.libsonnet"
      start="// begin_config\n"
      end="// end_config\n"
    %}
  }
}
```

## Exposed values

The following values are exposed, but not exported:

| Name                           | Contents                                                   |
|--------------------------------|------------------------------------------------------------|
| `mariadb.passwordSecretKeyRef` | A kubernetes `secretKeyRef`, referencing the user password |

## Starting multiple instances

Another way to use this module, is by calling the `newMariaDB` function. This
allows you to create multiple instances without polluting the global scope.

```.ts
{
  _config+:: {
    dbOne: {
      name: 'dbOne',
      user: 'foo',
      password: 'bar',
    },
    dbTwo: {
      name: 'dbTwo',
      user: 'foo',
      password: 'bar',
    }
  }
  dbOne: (import 'cloudflight-libsonnet/databases/mariadb.libsonnet').newMariaDB($._config.dbOne),
  dbTwo: (import 'cloudflight-libsonnet/databases/mariadb.libsonnet').newMariaDB($._config.dbTwo),
}
```
