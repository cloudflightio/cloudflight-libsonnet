{
  'clusterrole-digester-manager-role': {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: {
      labels: {
        'digester/system': 'yes',
      },
      name: 'digester-manager-role',
    },
    rules: [
      {
        apiGroups: [
          '',
        ],
        resources: [
          'secrets',
          'serviceaccounts',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
      {
        apiGroups: [
          'apiextensions.k8s.io',
        ],
        resources: [
          'customresourcedefinitions',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
      {
        apiGroups: [
          'admissionregistration.k8s.io',
        ],
        resources: [
          'mutatingwebhookconfigurations',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
      {
        apiGroups: [
          'admissionregistration.k8s.io',
        ],
        resourceNames: [
          'digester-mutating-webhook-configuration',
        ],
        resources: [
          'mutatingwebhookconfigurations',
        ],
        verbs: [
          'create',
          'delete',
          'get',
          'list',
          'patch',
          'update',
          'watch',
        ],
      },
    ],
  },
  'clusterrolebinding-digester-manager-rolebinding': {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      labels: {
        'digester/system': 'yes',
      },
      name: 'digester-manager-rolebinding',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'digester-manager-role',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: 'digester-admin',
        namespace: 'digester-system',
      },
    ],
  },
  'deployment-digester-controller-manager': {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      labels: {
        'control-plane': 'controller-manager',
        'digester/operation': 'webhook',
        'digester/system': 'yes',
      },
      name: 'digester-controller-manager',
      namespace: 'digester-system',
    },
    spec: {
      replicas: 3,
      selector: {
        matchLabels: {
          'control-plane': 'controller-manager',
          'digester/operation': 'webhook',
          'digester/system': 'yes',
        },
      },
      template: {
        metadata: {
          annotations: {
            'prometheus.io/port': '8888',
          },
          labels: {
            'control-plane': 'controller-manager',
            'digester/operation': 'webhook',
            'digester/system': 'yes',
          },
        },
        spec: {
          containers: [
            {
              args: [
                'webhook',
                '--cert-dir=/certs',
                '--disable-cert-rotation=false',
                '--dry-run=false',
                '--health-addr=:9090',
                '--metrics-addr=:8888',
                '--offline=false',
                '--port=8443',
              ],
              env: [
                {
                  name: 'DEBUG',
                  value: 'false',
                },
                {
                  name: 'POD_NAME',
                  valueFrom: {
                    fieldRef: {
                      fieldPath: 'metadata.name',
                    },
                  },
                },
                {
                  name: 'POD_NAMESPACE',
                  valueFrom: {
                    fieldRef: {
                      apiVersion: 'v1',
                      fieldPath: 'metadata.namespace',
                    },
                  },
                },
              ],
              image: 'ghcr.io/google/k8s-digester:v0.1.9@sha256:a087beba0a231bab17e97ee2a79a6131bb43269b367d07b17b5fffae964f6f82',
              livenessProbe: {
                httpGet: {
                  path: '/healthz',
                  port: 'healthz',
                },
              },
              name: 'manager',
              ports: [
                {
                  containerPort: 8443,
                  name: 'webhook-server',
                  protocol: 'TCP',
                },
                {
                  containerPort: 8888,
                  name: 'metrics',
                  protocol: 'TCP',
                },
                {
                  containerPort: 9090,
                  name: 'healthz',
                  protocol: 'TCP',
                },
              ],
              readinessProbe: {
                httpGet: {
                  path: '/readyz',
                  port: 'healthz',
                },
              },
              resources: {
                requests: {
                  cpu: '100m',
                  'ephemeral-storage': '256Mi',
                  memory: '256Mi',
                },
                limits: {
                  memory: '256Mi',
                },
              },
              securityContext: {
                allowPrivilegeEscalation: false,
                capabilities: {
                  drop: [
                    'all',
                  ],
                },
                readOnlyRootFilesystem: true,
                runAsGroup: 65532,
                runAsNonRoot: true,
                runAsUser: 65532,
              },
              volumeMounts: [
                {
                  mountPath: '/certs',
                  name: 'cert',
                  readOnly: true,
                },
              ],
            },
          ],
          nodeSelector: {
            'kubernetes.io/os': 'linux',
          },
          serviceAccountName: 'digester-admin',
          volumes: [
            {
              name: 'cert',
              secret: {
                defaultMode: 420,
                secretName: 'digester-webhook-server-cert',
              },
            },
          ],
        },
      },
    },
  },
  'mutatingwebhookconfiguration-digester-mutating-webhook-configuration': {
    apiVersion: 'admissionregistration.k8s.io/v1',
    kind: 'MutatingWebhookConfiguration',
    metadata: {
      labels: {
        'control-plane': 'controller-manager',
        'digester/operation': 'webhook',
        'digester/system': 'yes',
      },
      name: 'digester-mutating-webhook-configuration',
    },
    webhooks: [
      {
        admissionReviewVersions: [
          'v1',
          'v1beta1',
        ],
        clientConfig: {
          caBundle: 'Cg==',
          service: {
            name: 'digester-webhook-service',
            namespace: 'digester-system',
            path: '/v1/mutate',
          },
        },
        failurePolicy: 'Ignore',
        name: 'digester-webhook-service.digester-system.svc',
        namespaceSelector: {
          matchLabels: {
            'digest-resolution': 'enabled',
          },
        },
        reinvocationPolicy: 'IfNeeded',
        rules: [
          {
            apiGroups: [
              '',
            ],
            apiVersions: [
              'v1',
            ],
            operations: [
              'CREATE',
              'UPDATE',
            ],
            resources: [
              'pods',
              'podtemplates',
              'replicationcontrollers',
            ],
            scope: 'Namespaced',
          },
          {
            apiGroups: [
              'apps',
            ],
            apiVersions: [
              'v1',
            ],
            operations: [
              'CREATE',
              'UPDATE',
            ],
            resources: [
              'daemonsets',
              'deployments',
              'replicasets',
              'statefulsets',
            ],
            scope: 'Namespaced',
          },
          {
            apiGroups: [
              'batch',
            ],
            apiVersions: [
              'v1',
              'v1beta1',
            ],
            operations: [
              'CREATE',
              'UPDATE',
            ],
            resources: [
              'cronjobs',
              'jobs',
            ],
            scope: 'Namespaced',
          },
          {
            apiGroups: [
              'sources.knative.dev',
            ],
            apiVersions: [
              'v1',
            ],
            operations: [
              'CREATE',
              'UPDATE',
            ],
            resources: [
              'containersources',
            ],
            scope: 'Namespaced',
          },
        ],
        sideEffects: 'None',
        timeoutSeconds: 15,
      },
    ],
  },
  'namespace-digester-system': {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      labels: {
        'control-plane': 'controller-manager',
        'digester-injection': 'disabled',
        'digester/system': 'yes',
        'istio-injection': 'disabled',
      },
      name: 'digester-system',
    },
  },
  'role-digester-manager-role': {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'Role',
    metadata: {
      labels: {
        'digester/system': 'yes',
      },
      name: 'digester-manager-role',
      namespace: 'digester-system',
    },
    rules: [
      {
        apiGroups: [
          '',
        ],
        resources: [
          'secrets',
        ],
        verbs: [
          'create',
          'delete',
          'get',
          'list',
          'patch',
          'update',
          'watch',
        ],
      },
    ],
  },
  'rolebinding-digester-manager-rolebinding': {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'RoleBinding',
    metadata: {
      labels: {
        'digester/system': 'yes',
      },
      name: 'digester-manager-rolebinding',
      namespace: 'digester-system',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'Role',
      name: 'digester-manager-role',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: 'digester-admin',
        namespace: 'digester-system',
      },
    ],
  },
  'secret-digester-webhook-server-cert': {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      labels: {
        'control-plane': 'controller-manager',
        'digester/system': 'yes',
      },
      name: 'digester-webhook-server-cert',
      namespace: 'digester-system',
    },
  },
  'service-digester-webhook-service': {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      labels: {
        'control-plane': 'controller-manager',
        'digester/operation': 'webhook',
        'digester/system': 'yes',
      },
      name: 'digester-webhook-service',
      namespace: 'digester-system',
    },
    spec: {
      ports: [
        {
          port: 443,
          targetPort: 8443,
        },
      ],
      selector: {
        'control-plane': 'controller-manager',
        'digester/operation': 'webhook',
        'digester/system': 'yes',
      },
    },
  },
  'serviceaccount-digester-admin': {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      labels: {
        'control-plane': 'controller-manager',
        'digester/system': 'yes',
      },
      name: 'digester-admin',
      namespace: 'digester-system',
    },
  },
}
