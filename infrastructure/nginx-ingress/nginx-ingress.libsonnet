local manifest = (import './nginx-ingress.manifest.libsonnet');
local k = (import '../../prelude.libsonnet');

{
  _config+:: {
    // begin_config
    nginxingress: {
      name: 'nginx-ingress',
      loadBalancerIP: error 'you need a static loadbalancer (public ip)',
    }
    // end_config
  },

  newNginxIngress(config={}):: manifest + {

    local this = self,
    local cfg = $._config.ingress + config,

    "service-ingress-nginx-controller"+: {
      "spec"+: {
          loadBalancerIP: cfg.loadBalancerIP
      },
    },

    "deployment-ingress-nginx-controller"+: {
      "spec"+: {
        "template"+: {
          "spec"+: {
            "containers": [
              super.containers[0] + {
                "args": super.args + ["--watch-ingress-without-class"],
              },
            ] + super.containers[1:]
          }
        }
      }
    },
  },

  nginxingress: self.newNginxIngress(),
}