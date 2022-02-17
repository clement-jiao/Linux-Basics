# 获取 k8s admin token

## 介绍

我们用程序调用 Kubernetes API 时,需要使用 Kubernetes 的 Token，
Service Account 对象的作用，就是 Kubernetes 系统内置的一种“服务账户”，它是 Kubernetes 进行权限分配的对象。比如， Service Account A，可以只被允许对 Kubernetes API 进行 GET 操作，而 Service Account B，则可以有 Kubernetes API 的所有操作权限。

## 创建 kubernetes.io/service-account-token

创建一个k8s-admin.yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kube-system
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: dashboard-admin
subjects:
  - kind: ServiceAccount
    name: dashboard-admin
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

### 应用 k8s-admin.yaml 配置

```bash
kubectl apply -f k8s-admin.yaml
```

### 获取 admin-token 名字

```bash
[root@k8s-master01]$ kubectl get secret -n kube-system|grep admin
dashboard-admin-token-slc8x     kubernetes.io/service-account-token   3      2m
```

### 查询token内容

```bash
kubectl describe secret dashboard-admin-token-slc8x -n kube-system
Name:         dashboard-admin-token-slc8x
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: dashboard-admin
              kubernetes.io/service-account.uid: c1b01bec-c8a8-49b8-8199-c609d525e555

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1066 bytes
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IlE3MDhCbHxxxxxxxxxx
```

`token: eyJhbGciOiJSUzI1NiIsImtpZCI6IlE3MDhCbHxxxxxxxxxx`

由于token过长，这里用xxx代替。

最后将token与APISERVER地址返回内容复制到程序主机内, 供脚本使用。

## 通过 token 使用APIserver

```bash
TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6IlE3MDhCbHxxxxxxxxxx
IP_PORT=192.168.11.11:6443		# APIserver 或 VIP 或 haproxy
curl --cacert /etc/kubernetes/ssl/ca.pem -H "Authorization: Bearer $(TOKEN)" https://$(IP_PORT)
curl $(IP_PORT)/ 				# 返回所有的 API 列表
curl $(IP_PORT)/apis 			# 分组API
curl $(IP_PORT)/api/v1 			# 带具体版本号的API
curl $(IP_PORT)/metrics			# 指标数据
curl $(IP_PORT)/version			# API版本的信息
curl $(IP_PORT)/healthz/etcd	# 与 etcd 的心跳监测
curl $(IP_PORT)/apis/autoscaling/v1	# API 的详细信息
```
### API 的版本：
```tex
Alpha 预览版：可能包含 bug 或错误，后期版本会修复且不兼容之前的版本，不建议使用
Beta  测试版：如 storage.k8s.io/v1beta1，该版本可能存在不稳定或潜在bug，不建议生产使用。
v1    测试版：如 apps/v1，经过验证的 stable 版本，可以在生产环境使用
```



## 参考资料

[如何获取 k8s admin token?](https://www.code404.icu/1401.html)