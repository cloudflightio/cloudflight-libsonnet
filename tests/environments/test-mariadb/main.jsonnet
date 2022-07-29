(import 'cloudflight-libsonnet/databases/mariadb.libsonnet')
// imported to test collisions
+ (import 'cloudflight-libsonnet/databases/redis.libsonnet')
+ {
  _config+: {
    mariadb+: {
      user: 'application-user',
      password: 'hunter2',
      database: 'my-application',
    },
    redis+: {
      password: null,
    },
  },
  extraDB: (import 'cloudflight-libsonnet/databases/mariadb.libsonnet').newMariaDB({
    name: 'otherDB',
    user: 'newUser',
    password: 'foobar',
  }),
}
