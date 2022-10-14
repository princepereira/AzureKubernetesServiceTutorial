# Windows CtsTraffic Deployment

CtsTraffic is client server test connection tool which can be run in Windows.

Ref: https://github.com/microsoft/ctsTraffic

#### 1. Create CtsTraffic Server Deployment

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
    app: cts-traffic-server
  name: cts-traffic-server
  namespace: demo
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: cts-traffic-server
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: cts-traffic-server
    spec:
      containers:
      - image: ueqt/ctstraffic
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

#### 2. Create CtsTraffic Server Service

```
File: server-svc.yaml
```
```
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cts-traffic-server
  name: cts-traffic-server
  namespace: demo
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  selector:
    app: cts-traffic-server
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

#### 3. Create CtsTraffic Client POD

```
>> kubectl run -it ctstraffic-client -n demo --image=ueqt/ctstraffic --command -- cmd
```

If the above session is ended, resume using below command:
```
>> kubectl attach ctstraffic-client -c ctstraffic-client -i -t -n demo
```

#### 4. Establish cient server connection

Get the service IP
```
>> kubectl get services -n demo
```
Connect client to server
```
client >> ctsTraffic.exe -target:<Server Service IP> -consoleverbosity:1 -statusfilename:clientstatus.csv -connectionfilename:clientconnections.csv
```
