{
  withK(k):: {
    java+: {
      livenessProbe+: {
        local lp = k.core.v1.container.livenessProbe,
        new(port=8080): lp.withFailureThreshold(5)
                        + lp.withInitialDelaySeconds(30)
                        + lp.withPeriodSeconds(10)
                        + lp.withSuccessThreshold(1)
                        + lp.withTimeoutSeconds(1)
                        + lp.tcpSocket.withPort(port),
      },
      readinessProbe+: {
        local rp = k.core.v1.container.readinessProbe,
        new(
          port=18080,
          path="/actuator/health"
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
        local port = k.core.v1.containerPort,
        new(name,
            image,
            port=8080,
            actuatorPort=port+1000,
            env={}
           ): container.new(name,image)
              + container.withPorts([
                port.new('http', port),
                port.new('actuator', actuatorPort),
              ])
              + container.withEnvMapMixin({
                'SPRING_PROFILES_ACTIVE': 'kubernetes',
              })
              + container.withEnvMapMixin(env)
              + container.resources.withRequests({
                cpu: '100m',
                memory: '1Gi',
              })
              + container.resources.withLimits({
                cpu: '500m',
                memory: '1Gi',
              })
              + k.utils.java.livenessProbe.new()
              + k.utils.java.readinessProbe.new(),

      },
      deployment+: {
        local deployment = k.apps.v1.deployment,
        new(name,image,replicas=1,env={}):
          deployment.new(name, replicas, containers=[
            k.utils.java.container.new(name,image,port=8080,env=env)
          ])
      }
    }
  }
}
