# Windows Tcp CLient Server Deployment

This will enable client server test connection tool which can be run in Windows.

Ref: https://github.com/microsoft/ctsTraffic

#### 1. Create TCP Server Deployment

Create namespace demo
```
>> kubectl create namespace demo
```

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
    app: tcp-server
  name: tcp-server
  namespace: demo
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: tcp-server
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: tcp-server
    spec:
      containers:
      - image: princepereira/tcp-client-server
        imagePullPolicy: Always
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

#### 2. Create TCP Server Service

```
File: server-svc.yaml
```
```
apiVersion: v1
kind: Service
metadata:
  labels:
    app: tcp-server
  name: tcp-server
  namespace: demo
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  selector:
    app: tcp-server
  sessionAffinity: None
  type: ClusterIP
  ports:
  - name: tcp
    port: 4444
    protocol: TCP
    targetPort: 4444
```
```
>> kubectl create -f server-svc.yaml
```

#### 3. Create TCP Client POD

```
>> kubectl run -it tcp-client -n demo --image=princepereira/tcp-client-server --command -- cmd
```

If the above session is ended, resume using below command:
```
>> kubectl attach tcp-client -c tcp-client -i -t -n demo
```

#### 4. Establish cient server connection

Get the service IP
```
>> kubectl get services -n demo
```

Connect client to server
```
client >> client 10.0.120.113:4444 100000
```
