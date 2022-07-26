(import 'test-java.libsonnet')
+ (import 'cloudflight-libsonnet/applications/spring-boot-admin.libsonnet')
+ {
  _config+: {
    springBootAdmin+: {
      host: 'sba.internal.cloudflight.dev',
    },
    myApplication+: {
      image: 'spring-boot-hello-world',
    },
  },
}
