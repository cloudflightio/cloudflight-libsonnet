# What are modules?

Modules are ready-to-use setups of existing applications and services. To use
them, import them into your `main.libsonnet` like so:

```ts
(import 'cloudflight-libsonnet/databases/mariadb.libsonnet') + {
  _config+: {
    mariadb+: {
      user: 'foo',
      password: 'bar',
    }
  }
}
```
