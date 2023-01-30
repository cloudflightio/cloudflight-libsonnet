# Mailhog

This module creates an instance of
[mailhog](https://github.com/mailhog/MailHog). Data is stored in memory only so
messages will disappear after a pod restart.

The following snippet lists all available configuration options alongside their default values:

```.ts
(import 'cloudflight-libsonnet/applications/spring-boot-admin.libsonnet')
+ {
  _config+: {
    {%
      include "../../../applications/spring-boot-admin.libsonnet"
      start="// begin_config\n"
      end="// end_config\n"
    %}
  }
}
```
