local k = import '../prelude.libsonnet';
local p = import 'github.com/jsonnet-libs/kube-prometheus-libsonnet/0.10/main.libsonnet';
{
  _config+:: {
    // begin_config
    redis: {
      name: 'redis',
      replicas: 3,
      image: 'registry.redhat.io/rhel8/redis-6:1-72',
      exporterImage: 'docker.io/oliver006/redis_exporter:v1.43.0',
      password: error 'cfg.password must either be defined or set to null',
      topologyKey: 'kubernetes.io/hostname',
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
  newRedisCluster(config):: {
    local this = self,


    local cfg = $._config.redis + config,
    local statefulset = k.apps.v1.statefulSet,
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
    },
    config: cm.new(cfg.name, {
      'post-init.sh': |||
        if [[ -n "$REDIS_PASSWORD" ]]; then
          echo "enabling masterauth"
          echo "masterauth ${REDIS_PASSWORD}" >> $REDIS_CONF
        fi

        if [[ "${SENTINEL-false}" == "true" ]]; then
          echo "configuring sentinel"
          echo "bind 0.0.0.0" >> $REDIS_CONF
          echo "sentinel announce-ip $POD_IP" >> $REDIS_CONF
          echo "sentinel announce-port 6379" >> $REDIS_CONF
          echo "sentinel monitor main ${HOSTNAME%-*}-0.$SERVICE_NAME 6379 $QUORUM" >> $REDIS_CONF
          if [[ -n "$REDIS_PASSWORD" ]]; then
            echo "sentinel auth-pass main ${REDIS_PASSWORD}" >> $REDIS_CONF
          fi
        else
          if [[ $HOSTNAME == *-0 ]]; then
            echo "running on the intended primary"
          else
            echo "running on a replica"
            echo "replicaof ${HOSTNAME%-*}-0.$SERVICE_NAME 6379" >> $REDIS_CONF
          fi
        fi
      |||,
    }),
    redisCluster: statefulset.new(name=cfg.name, replicas=cfg.replicas, containers=[
                    container.new(name='redis', image=cfg.image)
                    + container.withPorts([
                      port.new('redis', 6379),
                    ])
                    + container.withEnvMap({
                      SERVICE_NAME: this.hlService.metadata.name,
                    })
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
                    container.new(name='sentinel', image=cfg.image)
                    + container.withPorts([
                      port.new('sentinel', 26379),
                    ])
                    + container.withEnvMap({
                      SERVICE_NAME: this.hlService.metadata.name,
                      REDIS_CONF: '/tmp/redis-sentinel.conf',
                      SENTINEL: 'true',
                      QUORUM: '' + (std.floor(cfg.replicas / 2) + 1),
                    })
                    + container.withEnvMixin([{
                      name: 'POD_IP',
                      valueFrom: {
                        fieldRef: {
                          fieldPath: 'status.podIP',
                        },
                      },
                    }])
                    + container.withArgs(['run-redis', '--sentinel'])
                    + container.resources.withRequests({
                      cpu: '10m',
                      memory: '64Mi',
                    })
                    + container.resources.withLimits({
                      cpu: '50m',
                      memory: '128Mi',
                    })
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
                  + statefulset.spec.withServiceName(self.hlService.metadata.name)
                  + statefulset.configMapVolumeMount(self.config, '/usr/share/container-scripts/redis/post-init.sh', volumeMountMixin={ subPath: 'post-init.sh' })
                  + statefulset.spec.withVolumeClaimTemplates(if cfg.storage != null then
                    [
                      pvc.new('data')
                      + pvc.spec.withAccessModes('ReadWriteOnce')
                      + pvc.spec.resources.withRequests({ storage: cfg.storage }),
                    ]
                  else []),
    hlService: k.util.serviceFor(self.redisCluster)
               + k.core.v1.service.metadata.withName(cfg.name + '-hl')
               + k.core.v1.service.spec.withPublishNotReadyAddresses(true)
               + k.core.v1.service.spec.withClusterIp('None'),
    serviceMonitor: p.monitoring.v1.serviceMonitor.new(cfg.name)
                    + p.monitoring.v1.serviceMonitor.spec.selector.withMatchLabels(self.hlService.metadata.labels)
                    + p.monitoring.v1.serviceMonitor.spec.withEndpoints([{ targetPort: 9121 }]),
  },
  redis: self.newRedisCluster({}),
}
