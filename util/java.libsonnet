local d = import 'github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet';
{
  withK(k):: {
    '#java': d.obj('java holds my functions related to java based applications'),
    java+: {
      livenessProbe+: {
        local lp = k.core.v1.container.livenessProbe,
        '#new': d.fn(|||
          new constructs a fresh liveness probe, checking if the tcp port 8080 is open
        |||, [d.arg('port', d.T.number, 8080), d.arg('initialDelaySeconds', d.T.number, 30)]),
        new(
          port=8080,
          initialDelaySeconds=30
        ): lp.withFailureThreshold(5)
           + lp.withInitialDelaySeconds(initialDelaySeconds)
           + lp.withPeriodSeconds(10)
           + lp.withSuccessThreshold(1)
           + lp.withTimeoutSeconds(1)
           + lp.tcpSocket.withPort(port),
      },
      readinessProbe+: {
        local rp = k.core.v1.container.readinessProbe,
        '#new': d.fn(|||
          new constructs a fresh readiness probe, checking if the application
          is up. The port and path of the actuator endpoint can be changed
          using the parameters.
        |||, [d.arg('port', d.T.number, 18080), d.arg('path', d.T.string, '/actuator/health')]),
        new(
          port=18080,
          path='/actuator/health'
        ): rp.withFailureThreshold(5)
           + rp.withInitialDelaySeconds(30)
           + rp.withPeriodSeconds(10)
           + rp.withSuccessThreshold(1)
           + rp.withTimeoutSeconds(1)
           + rp.httpGet.withPort(port)
           + rp.httpGet.withPath(path),
      },
      container+: {
        local container = k.core.v1.container,
        local p = k.core.v1.containerPort,
        '#new': d.fn(|||
          constructs a container with reccomended settings for Java/Spring Boot applications.
          Includes liveness- and readiness probes, activates the `kubernetes` spring profile
          and sets sensible resource defaults.
        |||, [
          d.arg('name', d.T.string),
          d.arg('image', d.T.string),
          d.arg('port', d.T.number, 8080),
          d.arg('actuatorPort', d.T.number, 'port+8080'),
          d.arg('env', d.T.object, {}),
        ]),
        new(
          name,
          image,
          port=8080,
          actuatorPort=port + 10000,
          env={}
        ): container.new(name, image)
           + container.withPorts([
             p.new('http', port),
           ])
           + (if actuatorPort != port then container.withPortsMixin([p.new('actuator', actuatorPort)]) else {})
           + container.withEnvMap({
             SPRING_PROFILES_ACTIVE: 'kubernetes',
           } + env)
           + container.resources.withRequests({
             cpu: '100m',
             memory: '1Gi',
           })
           + container.resources.withLimits({
             cpu: '500m',
             memory: '1Gi',
           })
           + k.util.java.livenessProbe.new()
           + k.util.java.readinessProbe.new(actuatorPort),

      },
      deployment+: {
        local deployment = k.apps.v1.deployment,
        '#new': d.fn(|||
          constructs a deployment using the java container. If you need more control, construct this deployment yourself.

          The `runtime` and `component` parameters are used to prefill reccomended labels
        |||, [
          d.arg('name', d.T.string),
          d.arg('image', d.T.string),
          d.arg('replicas', d.T.number, 1),
          d.arg('env', d.T.object, {}),
          d.arg('runtime', d.T.string, 'spring-boot'),
          d.arg('component', d.T.string, 'backend'),
        ]),
        new(name, image, replicas=1, env={}, runtime='spring-boot', component='backend'):
          deployment.new(name, replicas, containers=[
            k.util.java.container.new(name, image, port=8080, env=env),
          ])
          + deployment.metadata.withLabelsMixin({
            'app.openshift.io/runtime': runtime,
            'app.kubernetes.io/name': name,
            'app.kubernetes.io/component': component,
          }),
      },
    },
  },
}
