local k = (import 'cloudflight-libsonnet/prelude.libsonnet');
{
  _config+:: {
    myApplication: {
      name: 'my-application',
      image: error '$._config.myApplication.image must be defined',
    },
  },
  myApplication: {
    deployment: k.apps.v1.deployment.new(
                  name=$._config.myApplication.name,
                  replicas=2,
                  containers=[
                    k.util.java.container.new($._config.myApplication.name, $._config.myApplication.image)
                    + k.core.v1.container.withVolumeMounts([
                      k.core.v1.volumeMount.new(name='temp', mountPath='/opt/cache'),
                    ]),
                  ]
                )
                + k.apps.v1.deployment.spec.template.spec.withVolumes([
                  k.core.v1.volume.fromEmptyDir(name='temp'),
                ]),
    service: k.util.serviceFor(self.deployment),
    route: k.util.routeFor(self.service, 'hello.example.com'),
  },
}
