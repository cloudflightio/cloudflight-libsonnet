local k = import '../prelude.libsonnet';
local p = import 'github.com/jsonnet-libs/kube-prometheus-libsonnet/0.10/main.libsonnet';
{
  _config+:: {
    // begin_config
    mssql: {
      name: 'mssql',
      storage: '5Gi',
      // The password must be at least 8 characters long and contain characters from three of the following four sets: Uppercase letters, Lowercase letters, Base 10 digits, and Symbols
      rootPassword: error 'cfg.rootPassword must be defined',
      productId: 'Developer',
      image: 'mcr.microsoft.com/mssql/rhel/server:2022-latest',
      acceptEula: false,
      resources:: {
        limits: {
          cpu: '500m',
          memory: '2Gi',
        },
        requests: {
          cpu: '200m',
          memory: '2Gi',
        },
      },
    },
    // end_config
  },
  newMssql(config):: {
    local this = self,

    local cfg = $._config.mssql + config,
    assert cfg.acceptEula : 'You must accept the MSSQL Eula',
    local statefulSet = k.apps.v1.statefulSet,
    local container = k.core.v1.container,
    local port = k.core.v1.containerPort,
    local volumeMount = k.core.v1.volumeMount,
    local volume = k.core.v1.volume,
    local secret = k.core.v1.secret,
    local cm = k.core.v1.configMap,
    local pvc = k.core.v1.persistentVolumeClaim,
    local is = k.image.v1.imageStream,
    secret: secret.new(name=cfg.name, data={})
            + secret.withStringData({
              MSSQL_SA_PASSWORD: cfg.rootPassword,
            }),

    statefulSet: statefulSet.new(name=cfg.name, replicas=1, containers=[
                   container.new(name='mssql', image=cfg.image)
                   + container.withPorts([
                     port.new('mssql', 1433),
                   ])
                   + container.withVolumeMounts([
                     volumeMount.new(name='data', mountPath='/var/opt/mssql'),
                   ])
                   + container.withEnvMap({
                     ACCEPT_EULA: std.toString(cfg.acceptEula),
                     MSSQL_PID: cfg.productId,
                     MSSQL_AGENT_ENABLED: 'true',
                   })
                   + container.withEnvFrom([
                     {
                       secretRef: { name: this.secret.metadata.name },
                     },
                   ])
                   + container.securityContext.capabilities.withAdd('NET_BIND_SERVICE')
                   + container.resources.withRequests(cfg.resources.requests)
                   + container.resources.withLimits(cfg.resources.limits)
                   + container.readinessProbe.withFailureThreshold(5)
                   + container.readinessProbe.withInitialDelaySeconds(30)
                   + container.readinessProbe.withPeriodSeconds(10)
                   + container.readinessProbe.withSuccessThreshold(1)
                   + container.readinessProbe.withTimeoutSeconds(1)
                   + container.readinessProbe.tcpSocket.withPort(1433),
                 ])
                 + statefulSet.spec.withServiceName(self.service.metadata.name)
                 + statefulSet.spec.withVolumeClaimTemplates([
                   pvc.new('data')
                   + pvc.spec.withAccessModes('ReadWriteOnce')
                   + pvc.spec.resources.withRequests({ storage: cfg.storage }),
                 ]),
    service: k.util.serviceFor(self.statefulSet),
    passwordSecretKeyRef:: { name: cfg.name, key: 'MSSQL_SA_PASSWORD' },
  },
  mssql: self.newMssql({}),
}
