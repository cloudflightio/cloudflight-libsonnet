(import 'cloudflight-libsonnet/infrastructure/nginx-ingress/nginx-ingress.libsonnet') + 
{
    _config+:: {
        ingress: {
            loadBalancerIP: "1.1.1.0"
        },
        ingress1: {
            loadBalancerIP: "1.1.1.1"
        },
        ingress2: {
            loadBalancerIP: "1.1.1.2"
        },
    },
    ingressController1: $.newNginxIngress($._config.ingress1),
    ingressController2: $.newNginxIngress($._config.ingress2),
} + {
    local checkLBIP(o,c) = o['service-ingress-nginx-controller'].spec.loadBalancerIP == c.loadBalancerIP,
    assert std.isObject($.ingress),
    assert std.isObject($.ingressController1),
    assert std.isObject($.ingressController2),
    assert checkLBIP($.ingress, $._config.ingress),
    assert checkLBIP($.ingressController1, $._config.ingress1),
    assert checkLBIP($.ingressController2, $._config.ingress2),
}
