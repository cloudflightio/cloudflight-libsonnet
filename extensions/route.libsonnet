{
  route+: {
   v1+: {
     route+: {
       // make it easier to set host and path as well as enable TLS by default
       new(name,host,path="/")::
         super.new(name)
         + super.spec.withHost(host)
         + super.spec.withPath(path)
         + super.spec.tls.withTermination("Edge")
         + super.spec.tls.withInsecureEdgeTerminationPolicy("Redirect")
     }
   }
  }
}
