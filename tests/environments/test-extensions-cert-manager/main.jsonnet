local k = (import '../../../prelude.libsonnet');
local ingress = k.networking.v1.ingress;

(import 'cloudflight-libsonnet/infrastructure/cert-manager/cert-manager.libsonnet')
+ {
  issuer: k.util.certmanager.issuer.new('admin@example.com'),
  ingress: ingress.new('test.example.com') + ingress.withCertMixin($.issuer),
}
