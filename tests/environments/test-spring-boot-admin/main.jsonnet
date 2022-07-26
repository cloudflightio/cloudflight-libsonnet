(import 'test-java.libsonnet')
+ (import 'cloudflight-libsonnet/applications/spring-boot-admin.libsonnet')
+ {
  _config+: {
    myApplication+: {
      image: 'spring-boot-hello-world',
    },
  },
}
