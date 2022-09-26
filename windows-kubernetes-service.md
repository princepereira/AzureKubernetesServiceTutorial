# Deploy a kubernetes service using windows containers

#### 1. Create server deployment

You can run server with pod alone as well as [deployment + service]. If you need only a single server pod, then follow the below command.
```
>> kubectl run server -n demo --image=k8s.gcr.io/e2e-test-images/agnhost:2.33 --labels="app=server" --port=80 --command -- /agnhost serve-hostname --tcp --http=false --port "80"
```

If you need it as [deployment + service], then follow below command.
```
File: server-deployment.yaml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "2"
  labels:
    app: server-deployment
  name: server-deployment
  namespace: demo
spec:
  progressDeadlineSeconds: 600
  replicas: 3
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: server-deployment
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: server-deployment
    spec:
      containers:
      - command:
        - /agnhost
        - serve-hostname
        - --tcp
        - --http=false
        - --port
        - "80"
        image: k8s.gcr.io/e2e-test-images/agnhost:2.33
        imagePullPolicy: IfNotPresent
        name: agnhost
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
```

```
>> kubectl create -f server-deployment.yaml
```

#### 2. Create server service

```
File: server-svc.yaml
```
```
apiVersion: v1
kind: Service
metadata:
  labels:
    app: server
  name: server
  namespace: demo
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  selector:
    app: server
  sessionAffinity: None
  type: ClusterIP
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
```

```
>> kubectl create -f server-svc.yaml
```

#### 3. Create client pod

```
>> kubectl run -it client -n demo --image=k8s.gcr.io/e2e-test-images/agnhost:2.33 --command -- bash
```

The above command will create a container and enter the pod cli. If the above command is timed out, you can reattach to the pod using below command.

```
>> kubectl attach client -c client -i -t -n demo
```

#### 4. Make a client call to the server running

Get the service ip
```
>> kubectl get services -n demo
```

#### 5. If you want to use network policies:

Ingress Policy
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: demo-policy
  namespace: demo
spec:
  podSelector:
    matchLabels:
      app: server
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: client
    ports:
    - port: 80
      protocol: TCP
```
For the above command to work, your client pod should need a label as below.

```
>> kubectl label pod client -n demo app=client
```
Egress Policy 1 (Based on Port rules)
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: npm-port-selector
  namespace: demo
spec:
  podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          networking/namespace: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53

  - ports:
    - port: 80
      protocol: TCP
    - port: 443
      protocol: TCP
    - port: 8080
      protocol: TCP
    - port: 8081
      protocol: TCP
    - port: 8082
      protocol: TCP
    - port: 8083
      protocol: TCP
    - port: 9000
      protocol: TCP
    to:
    - podSelector: {}

  policyTypes:
  - Egress
```

Egress Policy 2 (Based on namespaceSelector)
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: npm-namespace-selector
  namespace: demo
spec:
  podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          networking/namespace: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53

  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          app: server

  policyTypes:
  - Egress
```
