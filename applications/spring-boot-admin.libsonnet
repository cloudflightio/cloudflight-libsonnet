local k = import '../prelude.libsonnet';
{
  _config+:: {
    // begin_config
    springBootAdmin: {
      name: 'spring-boot-admin',
      image: 'ghcr.io/cloudflightio/spring-boot-admin-docker:2.7.3',
      serviceAccountName: 'default',
      config: {
        spring: {
          cloud: {
            kubernetes: {
              discovery: {
                enabled: true,
                'service-labels': {
                  '[app.openshift.io/runtime]': 'spring-boot',
                },
                catalogServiceWatchDelay: 300,
                'primary-port-name': 'actuator',
              },
            },
          },
        },
      },
      resources:: {
        limits: {
          cpu: '500m',
          memory: '512Mi',
        },
        requests: {
          cpu: '10m',
          memory: '512Mi',
        },
      },
    },
    // end_config
  },
  springBootAdmin: {
    local deployment = k.apps.v1.deployment,
    local container = k.core.v1.container,
    local port = k.core.v1.containerPort,
    local volumeMount = k.core.v1.volumeMount,
    local volume = k.core.v1.volume,
    local secret = k.core.v1.secret,
    local cm = k.core.v1.configMap,
    local pvc = k.core.v1.persistentVolumeClaim,
    local is = k.image.v1.imageStream,
    config: cm.new($._config.springBootAdmin.name, data={
      'application.yaml': std.manifestYamlDoc($._config.springBootAdmin.config),
    }),

    deployment: deployment.new(name=$._config.springBootAdmin.name, replicas=1, containers=[
                  k.util.java.container.new(name='spring-boot-admin', image=$._config.springBootAdmin.image, actuatorPort=8080)
                  + container.withVolumeMounts([
                    volumeMount.new(name='config', mountPath='/deployments/application.yaml')
                    + volumeMount.withSubPath('application.yaml'),
                  ])
                  + container.resources.withRequests($._config.springBootAdmin.resources.requests)
                  + container.resources.withLimits($._config.springBootAdmin.resources.limits),
                ])
                + deployment.spec.template.spec.withServiceAccountName($._config.springBootAdmin.serviceAccountName)
                + deployment.spec.template.spec.withVolumes([
                  volume.fromConfigMap('config', self.config.metadata.name),
                ]),
    service: k.util.serviceFor(self.deployment),
  },
}
