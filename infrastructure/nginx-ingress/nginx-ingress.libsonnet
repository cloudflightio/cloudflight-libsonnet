local manifest = (import './nginx-ingress.manifest.libsonnet');
local k = (import '../../prelude.libsonnet');

{
  _config+:: {
    // begin_config
    nginxingress: {
      name: 'nginx-ingress',
      type: 'external',
      loadBalancerIP: error 'you need a static loadbalancer ip (public IP for external, internal IP for internal)',
      internalSubnetAzure: null,
      replicas: 2,
      defaultTlsCertificate: null,
    },
    // end_config
  },

  newNginxIngress(config={}):: manifest {


    local this = self,
    local cfg = $._config.nginxingress + config,

    // https://github.com/google/jsonnet/issues/234#issuecomment-275489855
    local join(a) =
      local notNull(i) = i != null;
      local maybeFlatten(acc, i) = if std.type(i) == "array" then acc + i else acc + [i];
      std.foldl(maybeFlatten, std.filter(notNull, a), []),

    'service-ingress-nginx-controller'+: if cfg.type == 'external' then {
      spec+: {
        loadBalancerIP: cfg.loadBalancerIP,
      },
    } else if cfg.type == 'internal-azure' then {
      metadata+: {
        annotations+: {
          'service.beta.kubernetes.io/azure-load-balancer-internal': 'true',
          'service.beta.kubernetes.io/azure-load-balancer-ipv4': cfg.loadBalancerIP,
          [if cfg.internalSubnetAzure != null then 'service.beta.kubernetes.io/azure-load-balancer-internal-subnet' else null]: cfg.internalSubnetAzure,
        },
      },
    },

    'deployment-ingress-nginx-controller'+: {
      spec+: {
        replicas: cfg.replicas,
        template+: {
          spec+: {
            containers: [
              super.containers[0] {
                args: join([super.args, 
                  '--watch-ingress-without-class', 
                  if cfg.defaultTlsCertificate != null then ['--default-ssl-certificate='+cfg.defaultTlsCertificate]
                ]),
              },
            ] + super.containers[1:],
          },
        },
      },
    },
  },

  nginxingress: self.newNginxIngress(),
}
