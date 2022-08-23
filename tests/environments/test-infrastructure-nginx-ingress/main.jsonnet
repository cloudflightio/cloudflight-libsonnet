(import 'cloudflight-libsonnet/infrastructure/nginx-ingress/nginx-ingress.libsonnet') + 
{
    _config+:: {
        nginxingress: {
            loadBalancerIP: "1.1.1.0"
        },
        nginxingress1: {
            loadBalancerIP: "1.1.1.1"
        },
        nginxingress2: {
            loadBalancerIP: "1.1.1.2"
        },
    },
    nginxingress1: $.newNginxIngress($._config.nginxingress1),
    nginxingress2: $.newNginxIngress($._config.nginxingress2),
} + {
    local checkLBIP(o,c) = o['service-ingress-nginx-controller'].spec.loadBalancerIP == c.loadBalancerIP,
    assert std.isObject($.nginxingress),
    assert std.isObject($.nginxingress1),
    assert std.isObject($.nginxingress2),
    assert checkLBIP($.nginxingress, $._config.nginxingress),
    assert checkLBIP($.nginxingress1, $._config.nginxingress1),
    assert checkLBIP($.nginxingress2, $._config.nginxingress2),
}
