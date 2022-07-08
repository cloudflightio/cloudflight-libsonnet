local k = (import '../prelude.libsonnet');
{
  _config+:: {
    redis: {
      name: 'redis',
      image: 'registry.redhat.io/rhel8/redis-6:1-62',
      exporterImage: 'docker.io/oliver006/redis_exporter:v1.43.0',
      password: error "$._config.redis.password must either be defined or set to null",
      storage: null,
      resources:: {
        limits: {
          cpu: '100m',
          memory: '2Gi',
        },
        requests: {
          cpu: '50m',
          memory: '1Gi',
        },
      },
    },
  },
  redis: {
    local deployment = k.apps.v1.deployment,
    local container = k.core.v1.container,
    local port = k.core.v1.containerPort,
    local volumeMount = k.core.v1.volumeMount,
    local volume = k.core.v1.volume,
    local secret = k.core.v1.secret,
    local cm = k.core.v1.configMap,
    local pvc = k.core.v1.persistentVolumeClaim,

    local livenessProbe = container.livenessProbe.withFailureThreshold(5)
                          + container.livenessProbe.withInitialDelaySeconds(10)
                          + container.livenessProbe.withPeriodSeconds(10)
                          + container.livenessProbe.withSuccessThreshold(1)
                          + container.livenessProbe.withTimeoutSeconds(1)
                          + container.livenessProbe.tcpSocket.withPort(6379),
    local readinessProbe = container.readinessProbe.withFailureThreshold(5)
                           + container.readinessProbe.withInitialDelaySeconds(10)
                           + container.readinessProbe.withPeriodSeconds(10)
                           + container.readinessProbe.withSuccessThreshold(1)
                           + container.readinessProbe.withTimeoutSeconds(1)
                           + container.readinessProbe.exec.withCommand([
                             'redis-cli', 'ping',
                           ]),
    [if $._config.redis.password != null then 'secret' else null]: secret.new($._config.redis.name,{})
                + secret.withStringData({
                  'REDIS_PASSWORD': $._config.redis.password,
                }),
    [if $._config.redis.storage != null then 'volume' else null]: pvc.new($._config.redis.name)
            + pvc.spec.resources.withRequests({
              storage: $._config.redis.storage,
            })
            + pvc.spec.withAccessModes(['ReadWriteOnce']),
    deployment: deployment.new(name=$._config.redis.name, replicas=1, containers=[
                  container.new(name='redis', image=$._config.redis.image)
                  + container.withPorts([
                    port.new('redis', 6379),
                  ])
                  + livenessProbe
                  + readinessProbe
                  + container.resources.withRequests($._config.redis.resources.requests)
                  + container.resources.withLimits($._config.redis.resources.limits)
                  + (if $._config.redis.password != null then container.withEnvFrom([
                    {
                      secretRef: { name: $.redis.secret.metadata.name },
                    },
                  ]) else {})
                  + (if $._config.redis.storage != null then container.withVolumeMounts([
                    volumeMount.new(name='data', mountPath='/var/lib/redis/data'),
                  ]) else {}),
                  container.new(name='exporter', image=$._config.redis.exporterImage)
                  + container.withEnvMap({
                    REDIS_ADDR: 'redis://127.0.0.1:6379',
                  })
                  + container.withPorts([
                    port.new('metrics', 9121),
                  ])
                  + container.readinessProbe.withFailureThreshold(5)
                  + container.readinessProbe.withInitialDelaySeconds(30)
                  + container.readinessProbe.withPeriodSeconds(10)
                  + container.readinessProbe.withSuccessThreshold(1)
                  + container.readinessProbe.withTimeoutSeconds(1)
                  + container.readinessProbe.httpGet.withPath('/')
                  + container.readinessProbe.httpGet.withPort(9121)
                  + container.livenessProbe.withFailureThreshold(5)
                  + container.livenessProbe.withInitialDelaySeconds(30)
                  + container.livenessProbe.withPeriodSeconds(10)
                  + container.livenessProbe.withSuccessThreshold(1)
                  + container.livenessProbe.withTimeoutSeconds(1)
                  + container.livenessProbe.tcpSocket.withPort(9121),
                ])
                + (if $._config.redis.storage != null then (
                  deployment.spec.strategy.withType('Recreate')
                  + deployment.spec.template.spec.withVolumes([
                    volume.fromPersistentVolumeClaim('data', self.volume.metadata.name),
                  ])
                ) else {}),
    service: k.util.serviceFor(self.deployment),
    serviceMonitor: k.monitoring.v1.serviceMonitor.new($._config.redis.name)
                    + k.monitoring.v1.serviceMonitor.spec.selector.withMatchLabels(self.service.metadata.labels)
                    + k.monitoring.v1.serviceMonitor.spec.withEndpoints([{ port: 'exporter-metrics' }]),
  },
}
