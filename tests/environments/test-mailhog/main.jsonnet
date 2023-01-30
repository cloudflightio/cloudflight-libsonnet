(import 'cloudflight-libsonnet/applications/mailhog.libsonnet')
+ {
  _config+: {
    mailhog+: {
      host: 'mailhog-test.internal.cloudflight.dev',
    },
  },
}
