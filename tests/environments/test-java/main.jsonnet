(import 'test-java.libsonnet')
+ {
  _config+: {
    myApplication+: {
      image: 'helloworld:latest',
    },
  },
}
