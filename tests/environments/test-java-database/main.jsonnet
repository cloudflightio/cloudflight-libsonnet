(import 'cloudflight-libsonnet/databases/mariadb.libsonnet')
+ (import 'test-java.libsonnet')
+ {
  _config+: {
    mariadb+: {
      user: 'application-user',
      password: 'hunter2',
      database: 'my-application',
    },
    myApplication+: {
      image: 'helloworld:latest',
      dbUser: $._config.mariadb.user,
      dbPasswordRef: $.mariadb.passwordSecretKeyRef,
      dbUrl: 'jdbc:mysql://' + $.mariadb.service.metadata.name + '/' + $._config.mariadb.database,
    },
  },
  mariadb2: (import 'cloudflight-libsonnet/databases/mariadb.libsonnet') + {
    _config+: {
      mariadb+: {
        name: 'foo',
        user: 'foo-user',
        password: 'foo-user',
      },
    },
  },
}
