# Spring Boot Admin

This module creates an instance of
[spring-boot-admin](https://github.com/codecentric/spring-boot-admin),
preconfigured to discover endpoints via Kubernetes.

The following snippets lists all available configuration options alongside their default values:

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

## Integration and Service Discovery

When using our [java helpers](../java_application.md), spring-boot-admin will
automatically discover provided services and their respective actuator
endpoints.

To customize the discovery, modify `$._config.springBootAdmin.config.spring.cloud.kubernetes.discovery` to match your labels.
