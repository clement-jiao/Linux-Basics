# kube-dashboard

Kubernetes Dashboard 是一个通用的、基于 web 的 Kubernetes 集群UI。它允许用户管理在集群中运行的应用程序，并对它们进行故障排除，以及管理集群本身。

GitHub： [kubernetes/dashboard (github.com)](https://github.com/kubernetes/dashboard)

## Install

To deploy Dashboard, execute following command:

```bash
root@k8s-master-1:~$ kubectl apply -f  https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
```

## Compatibility

**注意：change log 中 版本兼容性警告！**

以下为 `dashboard v2.4.0` 版本兼容情况

| Kubernetes version | 1.18 | 1.19 | 1.20 | 1.21 |
| ----------------- | ---- | ---- | ---- | ---- |
|   Compatibility    | ?    | ?    | ✓    | ✓    |

## 修改暴露端口类型

```bash
spec:
  ports:
    - port: 443
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
# ↓↓↓↓↓↓修改为↓↓↓↓↓↓
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30088
      # 注意端口必须为 30000-40000 之前，否则需要在 ansible 中更改。
  selector:
    k8s-app: kubernetes-dashboard
```

## 提交配置

```bash
root@k8s-master-1:~# kubectl apply -f dashboard.yaml 
namespace/kubernetes-dashboard unchanged
serviceaccount/kubernetes-dashboard unchanged
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
```

## 访问验证

查看 pods 与 svc

```bash
# 查看 pod 是否启动成功
root@k8s-master-1:~$ kubectl get pods -A|grep dashboard
kubernetes-dashboard   dashboard-metrics-scraper-c45b7869d-rx2ht   1/1     Running   0               7m51s
kubernetes-dashboard   kubernetes-dashboard-576cb95f94-bpwj4       1/1     Running   0               7m52s

# 查看 svc
root@k8s-master-1:~$ kubectl get svc -A
NAMESPACE    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default      kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP                  6d11h
kube-system  kube-dns     ClusterIP   10.100.0.2   <none>        53/UDP,53/TCP,9153/TCP   2d23h
k8s-dash     dash-metrics-scraper  ClusterIP   10.100.73.58    <none>        8000/TCP       9m
k8s-dash     k8s-dashboard         NodePort    10.100.45.240   <none>        443:30088/TCP  9m


# 查看 node 地址
root@k8s-master-1:~$ kubectl describe pod kubernetes-dashboard-55f94-bpwj4 -n kubernetes-dashboard |grep Node
Node:         192.168.11.19/192.168.11.19
Node-Selectors:              kubernetes.io/os=linux

```

由于更改类型为 nodeport ，所以会在每个 node 上监听此端口:

```bash
# node 1
root@k8s-node-1:~$ netstat -pantu|grep 30088
tcp        0      0 0.0.0.0:30088           0.0.0.0:*               LISTEN      384/kube-proxy

# node 2
root@k8s-node-2:~$ netstat -pantu|grep 30088
tcp        0      0 0.0.0.0:30088           0.0.0.0:*               LISTEN      405/kube-proxy
```

### TOKEN 验证

#### 创建用户

创建新用户 `kubectl apply -f user.yaml`

```yaml
# root@k8s-master-1:~$ cat user.yaml
# 在名为 kubernetes-dashboard 的 namespace 中创建一个 admin 用户
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard

---
apiVersion: rbac.authorization.k8s.io/v1
# 角色绑定
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard

# 创建用户成功
root@k8s-master-1:~$ kubectl apply -f admin-user.yaml 
serviceaccount/admin-user created
clusterrolebinding.rbac.authorization.k8s.io/admin-user created
```

获取 token 秘钥

```bash
# 查询用户
root@k8s-master-1:~$  kubectl get secrets -A|grep admin
kubernetes-dashboard   admin-user-token-w6c99      kubernetes.io/service-account-token   3      150m

# 查看用户详情中的 token （很长的一串将其复制在 web 中）
root@k8s-master-1:~$ kubectl describe secrets admin-user-token-w6c99 -n kubernetes-dashboard |grep token
Name:         admin-user-token-w6c99
Type:  kubernetes.io/service-account-token
token:      eyJhbGciOiJSUzI1Nxxxxxxxfqli3EUUy8IWA
```

将查询到的 token 填入到 web 中即可登录

### Kubeconfig



## 其他 dashboard

### rancher

[手动快速部署 | Rancher文档](https://docs.rancher.cn/docs/rancher2.5/quick-start-guide/deployment/quickstart-manual-setup/_index)

### kuboard

[Kuboard_Kubernetes教程_K8S安装_管理界面](https://kuboard.cn/)

[Kuboard介绍 | Kuboard](https://kuboard.cn/overview/share-coder.html#在线演示)

#### 快速安装

[安装 Kuboard v3 - 内建用户库 | Kuboard](https://kuboard.cn/install/v3/install-built-in.html#安装)

```bash
sudo docker run -d \
  --restart=unless-stopped \
  --name=kuboard \
  -p 80:80/tcp \
  -p 10081:10081/tcp \
  -e KUBOARD_ENDPOINT="http://192.168.11.22:80" \
  -e KUBOARD_AGENT_SERVER_TCP_PORT="10081" \
  -v /root/kuboard-data:/data \
  eipwork/kuboard:v3
  # 也可以使用镜像 swr.cn-east-2.myhuaweicloud.com/kuboard/kuboard:v3 ，可以更快地完成镜像下载。
  # 请不要使用 127.0.0.1 或者 localhost 作为内网 IP \
  # Kuboard 不需要和 K8S 在同一个网段，Kuboard Agent 甚至可以通过代理访问 Kuboard Server \

```

### kubesphere

### kubeOperater
