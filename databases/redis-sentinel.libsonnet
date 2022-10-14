local k = import '../prelude.libsonnet';
local p = import 'github.com/jsonnet-libs/kube-prometheus-libsonnet/0.10/main.libsonnet';
{
  _config+:: {
    // begin_config
    redis: {
      name: 'redis',
      replicas: 3,
      sentinels: 3,
      image: 'quay.io/fedora/redis-6:20221012',
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
      'post-init.sh': (|||
                         if [[ -n "$REDIS_PASSWORD" ]]; then
                           echo "enabling masterauth"
                           echo "masterauth ${REDIS_PASSWORD}" >> $REDIS_CONF
                           export REDISCLI_AUTH="${REDIS_PASSWORD}"
                         fi
                         echo "replica-announce-ip $HOSTNAME.$SERVICE_NAME" >> $REDIS_CONF
                         if [[ "${SENTINEL-false}" == "true" ]]; then
                           echo "configuring sentinel"
                           echo "bind 0.0.0.0" >> $REDIS_CONF
                           echo "sentinel myid $(echo $HOSTNAME | sha256sum | cut -c1-40)" >> $REDIS_CONF
                           echo "sentinel resolve-hostnames yes" >> $REDIS_CONF
                           echo "sentinel announce-hostnames yes" >> $REDIS_CONF
                           echo "sentinel monitor main %(name)s-0.$SERVICE_NAME 6379 $QUORUM" >> $REDIS_CONF
                           echo "sentinel down-after-milliseconds main 5000" >> $REDIS_CONF
                           echo "sentinel failover-timeout main 60000" >> $REDIS_CONF
                           echo "sentinel parallel-syncs main 1" >> $REDIS_CONF
                           if [[ -n "$REDIS_PASSWORD" ]]; then
                             echo "sentinel auth-pass main ${REDIS_PASSWORD}" >> $REDIS_CONF
                             echo "sentinel sentinel-pass ${REDIS_PASSWORD}" >> $REDIS_CONF
                           fi
                         else
                           if [ "$(redis-cli -h %(sentinelService)s -p 26379 ping)" != "PONG" ]; then
                             echo "Sentinel unavailable"
                             if [[ $HOSTNAME == *-0 ]]; then
                               echo "running on the intended primary"
                             else
                               echo "running replica"
                               echo "replicaof %(name)s-0.$SERVICE_NAME 6379" >> $REDIS_CONF
                             fi
                           else
                             echo "Sentinel found, finding master"
                             MASTER="$(redis-cli -h %(sentinelService)s -p 26379 --raw sentinel get-master-addr-by-name main | head -n 1)"
                             if [[ ${MASTER} == "$HOSTNAME.$SERVICE_NAME" ]]; then
                               echo "running on the intended primary"
                             else
                               echo "Master got: $MASTER, updating this in redis.conf"
                               echo "replicaof $MASTER 6379" >> $REDIS_CONF
                             fi
                           fi
                         fi
                       ||| % { name: this.redisCluster.metadata.name, sentinelService: this.sentinelService.metadata.name }),
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
                  ])
                  + statefulset.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution([
                    {
                      labelSelector: {
                        matchExpressions: [
                          { key: 'name', operator: 'In', values: [this.redisCluster.spec.template.metadata.labels.name] },
                        ],
                      },
                      topologyKey: cfg.topologyKey,
                    },
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
    sentinels: statefulset.new(name=cfg.name + '-sentinel', replicas=cfg.sentinels, containers=[
                 container.new(name='sentinel', image=cfg.image)
                 + container.withPorts([
                   port.new('sentinel', 26379),
                 ])
                 + container.withEnvMap({
                   SERVICE_NAME: this.hlService.metadata.name,
                   REDIS_CONF: '/tmp/redis-sentinel.conf',
                   SENTINEL: 'true',
                   QUORUM: '' + (std.floor(cfg.sentinels / 2) + 1),
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
                    ]) else {}),
               ])
               + statefulset.spec.withServiceName(self.sentinelService.metadata.name)
               + statefulset.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution([
                 {
                   labelSelector: {
                     matchExpressions: [
                       { key: 'name', operator: 'In', values: [this.sentinels.spec.template.metadata.labels.name] },
                     ],
                   },
                   topologyKey: cfg.topologyKey,
                 },
               ])
               + statefulset.configMapVolumeMount(self.config, '/usr/share/container-scripts/redis/post-init.sh', volumeMountMixin={ subPath: 'post-init.sh' }),
    hlService: k.util.serviceFor(self.redisCluster)
               + k.core.v1.service.metadata.withName(cfg.name + '-hl')
               + k.core.v1.service.spec.withPublishNotReadyAddresses(true)
               + k.core.v1.service.spec.withClusterIp('None'),
    sentinelService: k.util.serviceFor(self.sentinels)
                     + k.core.v1.service.metadata.withName(cfg.name + '-sentinel')
                     + k.core.v1.service.spec.withPublishNotReadyAddresses(true)
                     + k.core.v1.service.spec.withClusterIp('None'),
    serviceMonitor: p.monitoring.v1.serviceMonitor.new(cfg.name)
                    + p.monitoring.v1.serviceMonitor.spec.selector.withMatchLabels(self.hlService.metadata.labels)
                    + p.monitoring.v1.serviceMonitor.spec.withEndpoints([{ targetPort: 9121 }]),
  },
  redis: self.newRedisCluster({}),
}
