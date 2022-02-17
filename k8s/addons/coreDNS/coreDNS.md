# coreDNS

CoreDNS是一个DNS服务器/转发器，用Go编写，它链接了[插件](https://coredns.io/plugins)。每个插件执行一个 （DNS） 功能。

CoreDNS 是[云原生计算基金会](https://cncf.io/)毕业的项目。

CoreDNS是一个快速灵活的DNS服务器。这里的关键词是**灵活的**：使用CoreDNS，您可以通过利用插件对DNS数据执行所需的操作。如果没有开箱即用地提供某些功能，则可以通过[编写插件](https://coredns.io/explugins)来添加它。

CoreDNS可以侦听通过UDP / TCP（旧DNS），TLS（RFC[7858），](https://tools.ietf.org/html/rfc7858)也称为DoT，DNS over HTTP / 2 - DoH -[（RFC 8484）](https://tools.ietf.org/html/rfc8484)和[gRPC（](https://grpc.io/)不是标准）传入的DNS请求。

下载地址：[coredns/coredns (github.com)](https://github.com/coredns/coredns)， [kubernetes/CHANGELOG-1.23.md kubernetes (github.com)](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.23.md)

## 在 k8s 手动部署

yaml 示例模板

```bash
# 在 change log 中可以找到 k8s 源码包，下载后解压后可得
root@k8s-master-1:~$ ll /usr/local/src/
total 458M
drwxr-xr-x 10 root root 4.0K Dec 16 16:54 kubernetes
-rw-r--r--  1 root root  28M Dec 16 23:45 kubernetes-linux-amd64-1.22.5-client.tar.gz
-rw-r--r--  1 root root 114M Dec 16 23:45 kubernetes-linux-amd64-1.22.5-node.tar.gz
-rw-r--r--  1 root root 316M Dec 16 23:45 kubernetes-linux-amd64-1.22.5-server.tar.gz
-rw-r--r--  1 root root 553K Dec 16 23:45 kubernetes.tar.gz

# 进入到 coreDNS 目录可得示例模板
# 完整路径： /usr/local/src/kubernetes/cluster/addons/dns/coredns
root@k8s-master-1:/usr/local/src$ cd ./kubernetes/cluster/addons/dns/coredns/
root@k8s-master-1:/usr/local/src/kubernetes/cluster/addons/dns/coredns$ cp coredns.yaml.base ~

# 可以在上层目录找到其余受支持的 dns 组件
root@k8s-master-1:/usr/local/src/kubernetes/cluster/addons/dns$ ll
total 16K
drwxr-xr-x 2 root root 4.0K Jan 16 17:52 coredns
drwxr-xr-x 2 root root 4.0K Dec 16 16:54 kube-dns
drwxr-xr-x 2 root root 4.0K Dec 16 16:54 nodelocaldns
-rw-r--r-- 1 root root  129 Dec 16 16:54 OWNERS

# 可以再向上一层找到其余组件： calico、kuber-proxy、fluentd、dashboard等
root@k8s-master-1:/usr/local/src/kubernetes/cluster/addons$ ll
total 80K
drwxr-xr-x 2 root root 4.0K Dec 16 16:54 addon-manager
drwxr-xr-x 3 root root 4.0K Dec 16 16:54 calico-policy-controller
drwxr-xr-x 3 root root 4.0K Dec 16 16:54 cluster-loadbalancing
drwxr-xr-x 2 root root 4.0K Dec 16 16:54 dashboard
drwxr-xr-x 3 root root 4.0K Dec 16 16:54 device-plugins
drwxr-xr-x 5 root root 4.0K Jan 17 10:56 dns
...

```

修改示例模板，双下滑线字符为修改处：`__DNS__DOMAIN__ 、 __DNS__MEMORY__LIMIT__` 等

```yaml
# root@k8s-master-1:~$ vim /etc/kubeasz/clusters/clemente_cluster01/hosts
# Cluster DNS Domain
# CLUSTER_DNS_DOMAIN="clemente.local"
...
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        # __DNS__DOMAIN__ -> clemente.local
        kubernetes __DNS__DOMAIN__ in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        # prometheus 端口
        prometheus :9153
        # 非集群域名转发地址：可以写114.114.114.114、223.6.6.6或其他自建DNS服务器等
        forward . /etc/resolv.conf {
            max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
...
      - name: coredns
        image: k8s.gcr.io/coredns/coredns:v1.8.0
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            # 资源硬限制：__DNS__MEMORY__LIMIT__ -> 256Mi
            memory: __DNS__MEMORY__LIMIT__                                                                                               
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
...
spec:
  selector:
    k8s-app: kube-dns
  # 一般在容器的 /etc/resolv.conf 文件中可以找到
  # root@k8s-master-1:~$ kubectl exec -it net-nginx1 -n default -- cat /etc/resolv.conf
  # nameserver 10.100.0.2
  # search localdomain
  # 集群ip：__DNS__SERVER__ -> 10.100.0.2
  clusterIP: __DNS__SERVER__

```

## 修改镜像

```yaml
  # gcr下载失败可以去 dockerhub.com 下载。
  # k8s.gcr.io/coredns/coredns:v1.8.0 -> coredns/coredns:1.8.0
      containers:
      - name: coredns
        image: k8s.gcr.io/coredns/coredns:v1.8.0
```

### 查看日志

```bash
root@k8s-master-1:~$ kubectl logs coredns-7cd5f7d88c-4zln7 -n kube-system 
.:53
[INFO] plugin/reload: Running configuration MD5 = 0ee28762df7dd7529948eece6279a8f9
CoreDNS-1.8.0
linux/amd64, go1.15.3, 054c9ae
```

## 1.8.1 版本权限不足

**1.8.1 及以上版本**会提示 forbidden：根本原因是用户访问权限不足

```bash
E0117 09:12:38.914090       1 reflector.go:138] pkg/mod/k8s.io/client-go@v0.22.2/tools/cache/reflector.go:167: 
Failed to watch *v1.EndpointSlice: failed to list *v1.EndpointSlice: 
endpointslices.discovery.k8s.io is forbidden: User "system:serviceaccount:kube-system:coredns" cannot list resource "endpointslices" in API group "discovery.k8s.io" at the cluster scope

```

### 解决方法

如果出现 `Faild to watch *v1.EndpointSlice...` 是因为权限不足，需要在 coreDNS.yaml 文件 rules 中添加权限：

```yaml
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
  - watch
```

rules 完整示例：

```yaml
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  - services
  - pods
  - namespaces
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
  - watch
```

更改后重新授权：`kubectl apply -f coredns.yaml`

### 验证

```bash
root@k8s-master-1:~$ kubectl exec -it net-nginx1 -n default -- ping baidu.com
PING baidu.com (220.181.38.251) 56(84) bytes of data.
64 bytes from 220.181.38.251 (220.181.38.251): icmp_seq=1 ttl=127 time=30.8 ms
64 bytes from 220.181.38.251 (220.181.38.251): icmp_seq=2 ttl=127 time=30.3 ms
64 bytes from 220.181.38.251 (220.181.38.251): icmp_seq=3 ttl=127 time=30.8 ms
64 bytes from 220.181.38.251 (220.181.38.251): icmp_seq=4 ttl=127 time=32.4 ms
```

查看 coreDNS 日志：

```bash
# 没有以前的报错
root@k8s-master-1:~￥ kubectl logs -f --tail 10 coredns-5dfd59d5d8-db8rh -n kube-system
...
[INFO] plugin/ready: Still waiting on: "kubernetes"
[INFO] plugin/ready: Still waiting on: "kubernetes"
[INFO] plugin/ready: Still waiting on: "kubernetes"
```

### 跨名称空间访问

```bash
# 查看 DNS 地址
root@k8s-master-1:~$ kubectl get service -A
NAMESPACE     NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP                  3d13h
kube-system   kube-dns     ClusterIP   10.100.0.2   <none>        53/UDP,53/TCP,9153/TCP   131m

# 访问失败
root@k8s-master-1:~$ kubectl exec -it net-nginx1 -n default -- ping kube-dns
ping: kube-dns: Temporary failure in name resolution
command terminated with exit code 2

```

#### 填写完整 DNS 访问

```bash
# 跨名称空间访问需要填写完整路径
root@k8s-master-1:~$ kubectl exec -it net-nginx1 -n default -- ping kube-dns.kube-system.svc.clemente.local.
PING kube-dns.kube-system.svc.clemente.local (10.100.0.2) 56(84) bytes of data.
64 bytes from kube-dns.kube-system.svc.clemente.local (10.100.0.2): icmp_seq=1 ttl=64 time=0.050 ms
64 bytes from kube-dns.kube-system.svc.clemente.local (10.100.0.2): icmp_seq=2 ttl=64 time=0.070 ms
64 bytes from kube-dns.kube-system.svc.clemente.local (10.100.0.2): icmp_seq=3 ttl=64 time=0.060 ms
64 bytes from kube-dns.kube-system.svc.clemente.local (10.100.0.2): icmp_seq=4 ttl=64 time=0.069 ms

```

[01:52:55] (k8s DNS组件访问流程)

[01:55:35] (kube-DNS访问流程)



