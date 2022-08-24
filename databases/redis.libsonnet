local k = import '../prelude.libsonnet';
local p = import 'github.com/jsonnet-libs/kube-prometheus-libsonnet/0.10/main.libsonnet';
{
  _config+:: {
    // begin_config
    redis: {
      name: 'redis',
      image: 'registry.redhat.io/rhel8/redis-6:1-62',
      exporterImage: 'docker.io/oliver006/redis_exporter:v1.43.0',
      password: error 'cfg.password must either be defined or set to null',
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
    // end_config
  },
  newRedis(config):: {
    local this = self,


    local cfg = $._config.redis + config,
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
                             'redis-cli',
                             'ping',
                           ]),
    optionals: {
      [if cfg.password != null then 'secret' else null]: secret.new(cfg.name, {})
                                                         + secret.withStringData({
                                                           REDIS_PASSWORD: cfg.password,
                                                         }),
      [if cfg.storage != null then 'volume' else null]: pvc.new(cfg.name)
                                                        + pvc.spec.resources.withRequests({
                                                          storage: cfg.storage,
                                                        })
                                                        + pvc.spec.withAccessModes(['ReadWriteOnce']),
    },
    deployment: deployment.new(name=cfg.name, replicas=1, containers=[
                  container.new(name='redis', image=cfg.image)
                  + container.withPorts([
                    port.new('redis', 6379),
                  ])
                  + livenessProbe
                  + readinessProbe
                  + container.resources.withRequests(cfg.resources.requests)
                  + container.resources.withLimits(cfg.resources.limits)
                  + (if cfg.password != null then container.withEnvFrom([
                       {
                         secretRef: { name: this.optionals.secret.metadata.name },
                       },
                     ]) else {})
                  + (if cfg.storage != null then container.withVolumeMounts([
                       volumeMount.new(name='data', mountPath='/var/lib/redis/data'),
                     ]) else {}),
                  container.new(name='exporter', image=cfg.exporterImage)
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
                + (if cfg.storage != null then (
                     deployment.spec.strategy.withType('Recreate')
                     + deployment.spec.template.spec.withVolumes([
                       volume.fromPersistentVolumeClaim('data', self.optionals.volume.metadata.name),
                     ])
                   ) else {}),
    service: k.util.serviceFor(self.deployment),
    serviceMonitor: p.monitoring.v1.serviceMonitor.new(cfg.name)
                    + p.monitoring.v1.serviceMonitor.spec.selector.withMatchLabels(self.service.metadata.labels)
                    + p.monitoring.v1.serviceMonitor.spec.withEndpoints([{ targetPort: 9121 }]),
  },
  redis: self.newRedis({}),
}
