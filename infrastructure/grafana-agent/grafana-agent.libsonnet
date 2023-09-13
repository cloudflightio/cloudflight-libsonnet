local k = (import '../../prelude.libsonnet');

{
  _config+:: {
    // begin_config
    grafanaAgent: {
      image: 'docker.io/grafana/agent:v0.36.1',
    },
    // end_config
  },
  newGrafanaAgent(config={}):: {
    local this = self,

    local cfg = $._config.grafanaAgent + config,
    local deployment = k.apps.v1.deployment,
    local container = k.core.v1.container,
    local port = k.core.v1.containerPort,
    local volumeMount = k.core.v1.volumeMount,
    local volume = k.core.v1.volume,
    local secret = k.core.v1.secret,
    local cm = k.core.v1.configMap,
    local pvc = k.core.v1.persistentVolumeClaim,
    local is = k.image.v1.imageStream,
    local sa = k.core.v1.serviceAccount,
    local cr = k.rbac.v1.clusterRole,
    local crb = k.rbac.v1.clusterRoleBinding,
    local ds = k.apps.v1.daemonSet,
    local service = k.core.v1.service,

    local defaultSelectorLabels = {
      'app.kubernetes.io/name': 'grafana-agent',
      'app.kubernetes.io/instance': 'grafana-agent',
    },

    local defaultLabels = defaultSelectorLabels {
      'app.kubernetes.io/version': 'v0.36.1',
    },

    serviceaccount: sa.new('grafana-agent')
                    + sa.metadata.withLabelsMixin(defaultLabels),
    configmap: cm.new('grafana-agent')
               + cm.metadata.withLabelsMixin(defaultLabels)
               + cm.withData({
                 'config.river': (importstr 'config.river'),
               }),
    rbac_clusterrole: cr.new('grafana-agent')
                      + cr.metadata.withLabelsMixin(defaultLabels)
                      + cr.withRules([
                        {
                          apiGroups: [
                            '',
                            'discovery.k8s.io',
                            'networking.k8s.io',
                          ],
                          resources: [
                            'endpoints',
                            'endpointslices',
                            'ingresses',
                            'nodes',
                            'nodes/proxy',
                            'nodes/metrics',
                            'pods',
                            'services',
                          ],
                          verbs: [
                            'get',
                            'list',
                            'watch',
                          ],
                        },
                        {
                          apiGroups: [
                            '',
                          ],
                          resources: [
                            'pods',
                            'pods/log',
                            'namespaces',
                          ],
                          verbs: [
                            'get',
                            'list',
                            'watch',
                          ],
                        },
                        {
                          apiGroups: [
                            'monitoring.grafana.com',
                          ],
                          resources: [
                            'podlogs',
                          ],
                          verbs: [
                            'get',
                            'list',
                            'watch',
                          ],
                        },
                        {
                          apiGroups: [
                            'monitoring.coreos.com',
                          ],
                          resources: [
                            'prometheusrules',
                          ],
                          verbs: [
                            'get',
                            'list',
                            'watch',
                          ],
                        },
                        {
                          nonResourceURLs: [
                            '/metrics',
                          ],
                          verbs: [
                            'get',
                          ],
                        },
                        {
                          apiGroups: [
                            'monitoring.coreos.com',
                          ],
                          resources: [
                            'podmonitors',
                            'servicemonitors',
                            'probes',
                          ],
                          verbs: [
                            'get',
                            'list',
                            'watch',
                          ],
                        },
                        {
                          apiGroups: [
                            '',
                          ],
                          resources: [
                            'events',
                          ],
                          verbs: [
                            'get',
                            'list',
                            'watch',
                          ],
                        },
                      ]),
    rbac_clusterrolebinding: crb.new('grafana-agent')
                             + crb.metadata.withLabelsMixin(defaultLabels)
                             + crb.roleRef.withApiGroup('rbac.authorization.k8s.io')
                             + crb.roleRef.withKind('ClusterRole')
                             + crb.roleRef.withName('grafana-agent')
                             + crb.withSubjects([
                               {
                                 kind: 'ServiceAccount',
                                 name: 'grafana-agent',
                                 namespace: 'default',
                               },
                             ]),
    daemonset: ds.new('grafana-agent', containers=[
                 container.new(name='grafana-agent', image=cfg.image)
                 + container.withPorts([
                   port.new('http-metrics', 80),
                 ])
                 + container.withVolumeMounts([
                   volumeMount.new(name='config', mountPath='/etc/agent'),
                 ])
                 + container.withEnvMap({
                   AGENT_MODE: 'flow',
                 })
                 + container.withEnvMixin([
                   {
                     name: 'HOSTNAME',
                     valueFrom: {
                       fieldRef: {
                         fieldPath: 'spec.nodeName',
                       },
                     },
                   },
                 ])
                 + container.readinessProbe.withInitialDelaySeconds(10)
                 + container.readinessProbe.withTimeoutSeconds(1)
                 + container.readinessProbe.httpGet.withPath('/-/ready')
                 + container.readinessProbe.httpGet.withPort(80)
                 + container.withArgs([
                   'run',
                   '/etc/agent/config.river',
                   '--storage.path=/tmp/agent',
                   '--server.http.listen-addr=0.0.0.0:80',
                 ]),
                 container.new(name='config-reloader', image='docker.io/jimmidyson/configmap-reload:v0.8.0')
                 + container.withArgs([
                   '--volume-dir=/etc/agent',
                   '--webhook-url=http://localhost:80/-/reload',
                 ])
                 + container.withVolumeMounts(
                   volumeMount.new(name='config', mountPath='/etc/agent'),
                 )
                 + container.resources.withRequests({ cpu: '1m', memory: '5Mi' }),
               ])
               + ds.metadata.withLabelsMixin(defaultLabels)
               + ds.spec.withMinReadySeconds(10)
               + ds.spec.template.metadata.withLabelsMixin(defaultSelectorLabels)
               + ds.spec.template.spec.withServiceAccountName('grafana-agent')
               + ds.spec.template.spec.withDnsPolicy('ClusterFirst')
               + ds.spec.template.spec.withVolumes([
                 volume.fromConfigMap('config', self.configmap.metadata.name),
               ]),
    service: k.util.serviceFor(self.daemonset)
             + service.metadata.withLabelsMixin(defaultLabels),
  },

  grafanaAgent: self.newGrafanaAgent(),
}
