# Quick start

## Setting up
To start using this library, first initialize the working directory using `tk
init`.

This will create a directory structure similar to this:

```
.
├── environments
│   └── default
├── jsonnetfile.json
├── jsonnetfile.lock.json
├── lib
│   └── k.libsonnet
└── vendor
    ├── 1.23 -> github.com/jsonnet-libs/k8s-libsonnet/1.23
    ├── github.com
    └── ksonnet-util -> github.com/grafana/jsonnet-libs/ksonnet-util
```


Next, we need to install the `cloudflight-libsonnet` library using `jb`:

```bash
jb install github.com/cloudflightio/cloudflight-libsonnet@main
```

The last step is to adapt the predefined `k.libsonnet`. When initializing, Tanka
simply imports the
[`k8s-libsonnet`](https://github.com/jsonnet-libs/k8s-libsonnet) library here.
Since some of our customizations depend on other libraries which have to be
imported at this point (such as
[`openshift-libsonnet`](https://github.com/jsonnet-libs/openshift-libsonnet) or
[`prometheus-libsonnet`](https://github.com/jsonnet-libs/prometheus-operator-libsonnet)), you replace the contents of `k.libsonnet` with the
following:

```.ts
import 'github.com/cloudflightio/cloudflight-libsonnet/k.libsonnet'
```


## Using the library

To use the components provided by this library (or other Kubernetes components),
import our `prelude.libsonnet`.

Let's use the library to deploy a simple java based application, backed by an
MariaDB instance.

### Creating the application

Applications should be defined in the `lib` folder. To configure a java
application, we create a file called `lib/test-java.libsonnet` with the
contents below.

```.ts
{%
include "../../tests/environments/test-java/test-java.libsonnet"
%}
```

Now we can import this into our environment file
`environments/default/main.jsonnet`

```.ts
{%
include "../../tests/environments/test-java/main.jsonnet"
%}
```

Provided your `.kube/config` and `environments/default/spec.json` are set up
correctly, you can deploy this by running `tk apply environments/default`.

### Adding the database

Most applications want to store data somewhere so let's add a database next.
First, we import the database of choice in the `main.jsonnet` file.


```.ts
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
    },
  },
}
```

To connect our application to the database, we need to configure the deployment
on a lower level. This is because of the fact, that the plain
`util.java.deployment` does not make any assumptions about databases.

As documented in the java module, we build the deployment ourselves, but mix in
some environment variables.


```.ts
{%
include "../../tests/environments/test-java-database/test-java.libsonnet"
%}
```

In the last step, we fill the new config parameters with values.


```.ts
{%
include "../../tests/environments/test-java-database/main.jsonnet"
%}
```


And we're done!

To recap: we have configured an application, added a database
and connected it to our application. The way we connected the applications is
transparent, and we could (as long as the application supports it) change the
database entirely in our `main.jsonnet`. This way, we can use different database
setups across environment, while keeping the application configuration the same.

For more information, check out the documentation of the [java
utilities](../modules/java_application.md) and the [MariaDB
module](../modules/databases/mariadb.md).
