# MSSQL Database Module

This module contains a simple MSSQL instance, located in the `mssql` key.

The following snippets lists all available configuration options alongside their default values:


!!! info

    You need to set `acceptEula` to true to accept the MSSQL EULA



```.ts
(import 'cloudflight-libsonnet/databases/mssql.libsonnet')
+ {
  _config+: {
    {%
      include "../../../databases/mssql.libsonnet"
      start="// begin_config\n"
      end="// end_config\n"
    %}
  }
}
```

## Exposed values

The following values are exposed, but not exported:

| Name                         | Contents                                                 |
|------------------------------|----------------------------------------------------------|
| `mssql.passwordSecretKeyRef` | A kubernetes `secretKeyRef`, referencing the SA password |
