local k = import '../prelude.libsonnet';
{
  _config+:: {
    // begin_config
    mariadb: {
      name: 'mariadb',
      storage: '5Gi',
      user: error 'cfg.user must be defined',
      password: error 'cfg.password must be defined',
      database: self.user,
      image: 'registry.redhat.io/rhel8/mariadb-103:1-181',
      exporterImage: 'docker.io/prom/mysqld-exporter:v0.14.0',
      exporter_password: std.md5(self.password),
      resources:: {
        limits: {
          cpu: '500m',
          memory: '2Gi',
        },
        requests: {
          cpu: '200m',
          memory: '1Gi',
        },
      },
    },
    // end_config
  },
  newMariaDB(config):: {
    local this = self,

    local cfg = $._config.mariadb + config,
    local deployment = k.apps.v1.deployment,
    local container = k.core.v1.container,
    local port = k.core.v1.containerPort,
    local volumeMount = k.core.v1.volumeMount,
    local volume = k.core.v1.volume,
    local secret = k.core.v1.secret,
    local cm = k.core.v1.configMap,
    local pvc = k.core.v1.persistentVolumeClaim,
    local is = k.image.v1.imageStream,
    volume: pvc.new(cfg.name)
            + pvc.spec.resources.withRequests({
              storage: cfg.storage,
            })
            + pvc.spec.withAccessModes(['ReadWriteOnce']),
    secret: secret.new(name=cfg.name, data={})
            + secret.withStringData({
              MYSQL_USER: cfg.user,
              MYSQL_PASSWORD: cfg.password,
              MYSQL_DATABASE: cfg.database,
              MYSQL_EXPORTER_PASSWORD: cfg.exporter_password,
              DATA_SOURCE_NAME: self.MYSQL_USER + ':' + self.MYSQL_PASSWORD + '@(127.0.0.1:3306)/',
            }),
    initScripts: cm.new(cfg.name + '-init', data={
      'init.sql': |||
        CREATE USER IF NOT EXISTS 'exporter'@'127.0.0.1' IDENTIFIED BY '${MYSQL_EXPORTER_PASSWORD}';
        ALTER USER 'exporter'@'127.0.0.1' IDENTIFIED BY '${MYSQL_EXPORTER_PASSWORD}';
        GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'127.0.0.1';
      |||,
      '60-create-exporter-user.sh': |||
        envsubst < /usr/share/container-scripts/mysql/init/init.sql | mysql $mysql_flags
      |||,
    }),

    local livenessProbe = container.livenessProbe.withFailureThreshold(5)
                          + container.livenessProbe.withInitialDelaySeconds(30)
                          + container.livenessProbe.withPeriodSeconds(10)
                          + container.livenessProbe.withSuccessThreshold(1)
                          + container.livenessProbe.withTimeoutSeconds(1)
                          + container.livenessProbe.tcpSocket.withPort(3306),
    local readinessProbe = container.readinessProbe.withFailureThreshold(5)
                           + container.readinessProbe.withInitialDelaySeconds(30)
                           + container.readinessProbe.withPeriodSeconds(10)
                           + container.readinessProbe.withSuccessThreshold(1)
                           + container.readinessProbe.withTimeoutSeconds(1)
                           + container.readinessProbe.exec.withCommand([
                             '/bin/sh',
                             '-i',
                             '-c',
                             'mysqladmin ping',
                           ]),
    deployment: deployment.new(name=cfg.name, replicas=1, containers=[
                  container.new(name='mariadb', image=cfg.image)
                  + container.withPorts([
                    port.new('mariadb', 3306),
                  ])
                  + container.withVolumeMounts([
                    volumeMount.new(name='data', mountPath='/var/lib/mysql/data'),
                    volumeMount.new(name='init', mountPath='/usr/share/container-scripts/mysql/init/60-create-exporter-user.sh')
                    + volumeMount.withSubPath('60-create-exporter-user.sh'),
                    volumeMount.new(name='init', mountPath='/usr/share/container-scripts/mysql/init/init.sql')
                    + volumeMount.withSubPath('init.sql'),
                  ])
                  + container.withEnvMap({
                    MYSQL_DATABASE: cfg.database,
                    MYSQL_LOWER_CASE_TABLE_NAMES: '1',
                  })
                  + container.withEnvFrom([
                    {
                      secretRef: { name: this.secret.metadata.name },
                    },
                  ])
                  + livenessProbe
                  + readinessProbe
                  + container.resources.withRequests(cfg.resources.requests)
                  + container.resources.withLimits(cfg.resources.limits),
                  container.new(name='exporter', image=cfg.exporterImage)
                  + container.withArgs([
                    '--collect.info_schema.innodb_metrics',
                    '--collect.info_schema.innodb_tablespaces',
                    '--collect.info_schema.innodb_cmp',
                    '--collect.info_schema.innodb_cmpmem',
                    '--collect.engine_innodb_status',
                    '--collect.perf_schema.tablelocks',
                    '--collect.perf_schema.tableiowaits',
                    '--collect.perf_schema.indexiowaits',
                    '--collect.perf_schema.eventswaits',
                    '--collect.info_schema.tablestats',
                    '--collect.info_schema.userstats',
                    '--collect.info_schema.clientstats',
                    '--collect.info_schema.processlist',
                    '--collect.info_schema.tables',
                  ])
                  + container.withEnv([{
                    name: 'DATA_SOURCE_NAME',
                    valueFrom: { secretKeyRef: { name: this.secret.metadata.name, key: 'DATA_SOURCE_NAME' } },
                  }])
                  + container.withPorts([
                    port.new('metrics', 9104),
                  ])
                  + container.resources.withRequests({
                    cpu: '10m',
                    memory: '32Mi',
                  })
                  + container.resources.withLimits({
                    cpu: '100m',
                    memory: '128Mi',
                  })
                  + container.readinessProbe.withFailureThreshold(5)
                  + container.readinessProbe.withInitialDelaySeconds(30)
                  + container.readinessProbe.withPeriodSeconds(10)
                  + container.readinessProbe.withSuccessThreshold(1)
                  + container.readinessProbe.withTimeoutSeconds(1)
                  + container.readinessProbe.httpGet.withPath('/')
                  + container.readinessProbe.httpGet.withPort(9104)
                  + container.livenessProbe.withFailureThreshold(5)
                  + container.livenessProbe.withInitialDelaySeconds(30)
                  + container.livenessProbe.withPeriodSeconds(10)
                  + container.livenessProbe.withSuccessThreshold(1)
                  + container.livenessProbe.withTimeoutSeconds(1)
                  + container.livenessProbe.tcpSocket.withPort(9104),
                ])
                + deployment.spec.strategy.withType('Recreate')
                + deployment.spec.template.spec.withVolumes([
                  volume.fromPersistentVolumeClaim('data', self.volume.metadata.name),
                  volume.fromConfigMap('init', self.initScripts.metadata.name),
                ]),
    service: k.util.serviceFor(self.deployment),
    serviceMonitor: k.monitoring.v1.serviceMonitor.new(cfg.name)
                    + k.monitoring.v1.serviceMonitor.spec.selector.withMatchLabels(self.service.metadata.labels)
                    + k.monitoring.v1.serviceMonitor.spec.withEndpoints([{ targetPort: 9104 }]),

    passwordSecretKeyRef:: { name: cfg.name, key: 'MYSQL_PASSWORD' },
  },
  mariadb: self.newMariaDB({}),
}
