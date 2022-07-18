local k = (import 'cloudflight-libsonnet/prelude.libsonnet');
{
  _config+:: {
    myApplication: {
      name: 'my-application',
      image: error '$._config.myApplication.image must be defined',
      dbUser: error '$._config.myApplication.dbUser must be defined',
      dbPasswordRef: error '$._config.myApplication.dbPasswordRef must be a valid secretSecretKeyRef',
      dbUrl: error '$._config.myApplication.dbUrl must be defined',
    },
  },
  myApplication: {
    deployment: k.apps.v1.deployment.new(
      name=$._config.myApplication.name,
      replicas=1,
      containers=[
        k.util.java.container.new($._config.myApplication.name, $._config.myApplication.image)
        + k.core.v1.container.withEnvMixin([
          {
            name: 'SPRING_DATASOURCE_PASSWORD',
            valueFrom: { secretKeyRef: $._config.myApplication.dbPasswordRef },
          },
          {
            name: 'SPRING_DATASOURCE_USERNAME',
            value: $._config.myApplication.dbUser,
          },
          {
            name: 'SPRING_DATASOURCE_URL',
            value: $._config.myApplication.dbUrl,
          },
        ]),
      ]
    ),
    service: k.util.serviceFor(self.deployment),
    route: k.util.routeFor(self.service, 'hello.example.com'),
  },
}
