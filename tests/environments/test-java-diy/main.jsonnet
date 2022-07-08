(import 'test-java-diy.libsonnet')
+ {
  _config+: {
    myApplication+: {
      image: 'helloworld:latest',
    },
  },
}
