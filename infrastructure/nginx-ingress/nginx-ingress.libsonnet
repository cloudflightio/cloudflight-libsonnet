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
    },
    // end_config
  },

  newNginxIngress(config={}):: manifest {

    local this = self,
    local cfg = $._config.nginxingress + config,

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
                args: super.args + ['--watch-ingress-without-class'],
              },
            ] + super.containers[1:],
          },
        },
      },
    },
  },

  nginxingress: self.newNginxIngress(),
}
