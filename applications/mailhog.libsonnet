local k = import '../prelude.libsonnet';
{
  _config+:: {
    // begin_config
    mailhog: {
      name: 'mailhog',
      image: 'docker.io/anatomicjc/mailhog:1.0.1',
      host: error '$._config.mailhog.host must be defined',
      resources:: {
        limits: {
          cpu: '20m',
          memory: '128Mi',
        },
        requests: {
          cpu: '10m',
          memory: '64Mi',
        },
      },
    },
    // end_config
  },
  mailhog: {
    local deployment = k.apps.v1.deployment,
    local container = k.core.v1.container,
    local port = k.core.v1.containerPort,
    local volumeMount = k.core.v1.volumeMount,
    local volume = k.core.v1.volume,
    local secret = k.core.v1.secret,
    local cm = k.core.v1.configMap,
    local pvc = k.core.v1.persistentVolumeClaim,
    local is = k.image.v1.imageStream,
    deployment: deployment.new(name=$._config.mailhog.name, replicas=1, containers=[
      container.new(name='mailhog', image=$._config.mailhog.image)
      + container.resources.withRequests($._config.mailhog.resources.requests)
      + container.resources.withLimits($._config.mailhog.resources.limits)
      + container.livenessProbe.tcpSocket.withPort('http')
      + container.readinessProbe.httpGet.withPort('http')
      + container.readinessProbe.httpGet.withPath('/api/v2/messages?limit=0')
      + container.withPorts([
        port.new('http', 8025),
        port.new('smtp', 1025),
      ]),
    ]),
    service: k.util.serviceFor(self.deployment),
    ingress: k.util.ingressFor(self.service, $._config.mailhog.host),
  },
}
