# Migrating to Tanka

At Cloudflight we were previously using `kubecfg` to deploy our applications. As
of `2022-02-21`, [tanka](https://tanka.dev) is our recommended tool for
Kubernetes configurations. Reasoning for this can be found in ADR-0077.

If you're still using `kubecfg` you're in Luck! The migration to Tanka is very
simple and can be done in under five minutes.

!!! tip

    TL;DR:

    - Move stage files to environments/$NAME/main.jsonnet
    - Create environments/$NAME/spec.json
    - Fix Imports

## Verifying your current setup

Before we can start to migrate to the new setup, we should be confident
in the old one to avoid issues further down the line.

As a requirement, you should be able to view your configuration in the
yaml format by running

```bash
kubecfg show $YOUR_STAGE_FILE
```

## Restructuring

The main change required for a smooth workflow in Tanka, is a small restructuring
of the directory. Our old layout prescribes a flat structure with everything in
the root directory. Tanka on the other hand expects a folder per environment. To
perform this step, you need to go from this:

```
.
├── jsonnetfile.json
├── production.jsonnet
├── resources
│   └── application.jsonnet
└── staging.jsonnet
```

to

```bash
.
├── jsonnetfile.json
├── environments
│   ├── production
│   │   └── main.jsonnet # (1)
│   └── staging
│       └── main.jsonnet # (2)
└── lib
    └── application.libsonnet
```

1. The old `production.jsonnet`
2. The old `staging.jsonnet`

## Configuring

Instead of relying on the current Kubernetes context, Tanka needs
explicit information on the API Server as well as the namespace.

This information is saved in the `spec.json` file, contained in the
respective environment. The complete layout can be found in [the Tanka
documentation](https://tanka.dev/directory-structure)

The syntax is as follows:

```js
{
  "apiVersion": "tanka.dev/v1alpha1",
  "kind": "Environment",
  "metadata": {
    "name": "environments/staging"
  },
  "spec": {
    "apiServer": "openshift-dev.internal.cloudflight.io:6443", // (1)
    "namespace": "762-example-staging", // (2)
    "resourceDefaults": {},
    "expectVersions": {},
    "injectLabels": true
  }
}
```

1. API server URL. Excluding theh protocol, including the port
2. Namespace of your project. Will be injected to all resources

## Fixing Imports

Now that you moved around the files, you will also need to fix the
imports contained within them. For convenience, Tanka automatically
includes the `lib` and `vendor` directory in the jsonnet path. So
instead of having to write `../../lib/application.libsonnet` you can
simply import `application.libsonnet`.

## Verifying the new configuration

After fixing the imports, you can show the new configuration with the
following command:

```bash
tk show environments/staging
```

## TeamCity

Tanka integration from TeamCity is supported from version `3.0.0` of the cloudflight-teamcity-dsl onwards.

Example:

```kotlin
subCloudflightProject {
  name = "Deployment"
  tankaApply {
    openShiftConfig {
        serviceAccountToken = "credentialsJSON:..."
    }
    contextDir = ".openshift" // (1)
  }
}
```

1. Default: `deployment` as is the case with our new configuration skeleton
