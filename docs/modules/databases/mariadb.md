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
