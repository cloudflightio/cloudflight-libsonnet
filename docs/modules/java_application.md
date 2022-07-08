# Java Applications

Even though not strictyl a module, this library contains a lot of utility
functions to help you deploy Java applications. This page contains some ways
these functions can be used.


## All-in-one

This example contains the deployment of a simple spring boot based application.
It should be located somewhere like `lib/my-application.libsonnet`.

=== "jsonnet"

    ```.ts
    {%
    include "../../tests/environments/test-java/test-java.libsonnet"
    %}
    ```

=== "yaml"

    ```.yaml
    apiVersion: v1
    kind: Service
    metadata:
    labels:
        name: my-application
    name: my-application
    namespace: test-java
    spec:
    ports:
    - name: my-application-http
        port: 8080
        targetPort: 8080
    - name: my-application-actuator
        port: 9080
        targetPort: 9080
    selector:
        name: my-application
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: my-application
    namespace: test-java
    spec:
    minReadySeconds: 10
    replicas: 1
    revisionHistoryLimit: 10
    selector:
        matchLabels:
        name: my-application
    template:
        metadata:
        labels:
            name: my-application
        spec:
        containers:
        - env:
            - name: SPRING_PROFILES_ACTIVE
            value: kubernetes
            image: helloworld:latest
            imagePullPolicy: IfNotPresent
            livenessProbe:
            failureThreshold: 5
            initialDelaySeconds: 30
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
                port: 8080
            timeoutSeconds: 1
            name: my-application
            ports:
            - containerPort: 8080
            name: http
            - containerPort: 9080
            name: actuator
            readinessProbe:
            failureThreshold: 5
            httpGet:
                path: /actuator/health
                port: 18080
            initialDelaySeconds: 30
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
            resources:
            limits:
                cpu: 500m
                memory: 1Gi
            requests:
                cpu: 100m
                memory: 1Gi
    ---
    apiVersion: route.openshift.io/v1
    kind: Route
    metadata:
    name: my-application
    namespace: test-java
    spec:
    host: hello.example.com
    path: /
    port:
        targetPort: 8080
    tls:
        insecureEdgeTerminationPolicy: Redirect
        termination: Edge
    to:
        kind: Service
        name: my-application
    ```


Switch between the tabs to see the rendered output

## DIY

If you have the need for further customization, you can pick and choose parts of
the library you would like to use.

In this example, we want to modify the container so we use the
`util.java.container.new()` to get a base structure and extend it. This way, we
still have the defaults set, but are able to customize them to our hearts
content.


=== "jsonnet"

    ```.ts
    {%
    include "../../tests/environments/test-java-diy/test-java-diy.libsonnet"
    %}
    ```

=== "yaml"

    ```.yaml
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        name: my-application
      name: my-application
      namespace: test-java-diy
    spec:
      ports:
      - name: my-application-http
        port: 8080
        targetPort: 8080
      - name: my-application-actuator
        port: 9080
        targetPort: 9080
      selector:
        name: my-application
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-application
      namespace: test-java-diy
    spec:
      minReadySeconds: 10
      replicas: 2
      revisionHistoryLimit: 10
      selector:
        matchLabels:
          name: my-application
      template:
        metadata:
          labels:
            name: my-application
        spec:
          containers:
          - env:
            - name: SPRING_PROFILES_ACTIVE
              value: kubernetes
            image: helloworld:latest
            imagePullPolicy: IfNotPresent
            livenessProbe:
              failureThreshold: 5
              initialDelaySeconds: 30
              periodSeconds: 10
              successThreshold: 1
              tcpSocket:
                port: 8080
              timeoutSeconds: 1
            name: my-application
            ports:
            - containerPort: 8080
              name: http
            - containerPort: 9080
              name: actuator
            readinessProbe:
              failureThreshold: 5
              httpGet:
                path: /actuator/health
                port: 18080
              initialDelaySeconds: 30
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 1
            resources:
              limits:
                cpu: 500m
                memory: 1Gi
              requests:
                cpu: 100m
                memory: 1Gi
            volumeMounts:
            - mountPath: /opt/cache
              name: temp
          volumes:
          - emptyDir: {}
            name: temp
    ---
    apiVersion: route.openshift.io/v1
    kind: Route
    metadata:
      name: my-application
      namespace: test-java-diy
    spec:
      host: hello.example.com
      path: /
      port:
        targetPort: 8080
      tls:
        insecureEdgeTerminationPolicy: Redirect
        termination: Edge
      to:
        kind: Service
        name: my-application

    ```
