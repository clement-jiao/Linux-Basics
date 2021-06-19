[toc]



### 标签 selector

#### 显示所有标签

```bash
kc get pods --show-labels
# NAME                            READY   STATUS    RESTARTS   AGE   LABELS
# mage-app-dep-467z4   1/1     Running   0          35h   app=mage-app-dep,pod-template-hash=74f6f6d8c6
# mage-app-dep-5gl72   1/1     Running   0          35h   app=mage-app-dep,pod-template-hash=74f6f6d8c6

# APP：pod控制器名称
# pod-template-hash：pod 模板哈希指纹
```

#### 在模板中定义标签

因为标签属于元数据，所以需要在 `metadata` 中定义。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: clement-metadata-name		# pod name
  namespace: clement-metadata-namespace		# namespace
  labels:
    app: mage-app
    rel: canary
spec:
  containers:
  - name: clement-container-name
    image: ikubernetes/myapp:v7

```

#### 添加/覆改写标签

```bash
kc label --overwrite clement-pod-name -n clement-namespace tier=frontend app=myapp
# NAME                    READY   STATUS    RESTARTS   AGE   LABELS
# clement-metadata-name   1/1     Running   0          41m   app=myapp,rel=canary,tier=frontend
```

#### 删除标签

在 `key` 后面加 `-` 号：`tier-` 、`app-` 等

```bash
kc label pods clement-metadata-name -n clement-metadata-namespace tier-
# pod/clement-metadata-name labeled
kc get pods --show-labels -n clement-metadata-namespace
# NAME                    READY   STATUS    RESTARTS   AGE   LABELS
# clement-metadata-name   1/1     Running   0          45m   app=myapp,rel=canary
```

#### 查找标签

```bash
# 指定 value 标签
kc get pods -A --show-labels -l app=myapp
# NAMESPACE                    NAME                    READY   STATUS    RESTARTS   AGE   LABELS
# clement-metadata-namespace   clement-metadata-name   1/1     Running   0          49m   app=myapp,rel=canary

# 非 value 标签 (多个)
kc get pods -l '!app, !pod-template-hash, !controller-revision-hash' -A --show-labels
# NAMESPACE     NAME                  READY   STATUS    RESTARTS   AGE    LABELS
# hnp           hostnetworkpod        1/1     Running   0          25h    <none>
# hnp           hostnetworkpod-1      1/1     Running   0          25h    <none>
# kube-system   etcd-master           1/1     Running   0          3d5h   component=etcd,tier=control-plane

# 多 value 标签 (in,notin)
kc get pods -A --show-labels -l 'app in(myapp,mage-app-dep)'
# NAMESPACE           NAME                READY   STATUS    RESTARTS   AGE   LABELS
# clement-namespace   clement-name        1/1     Running   0          52m   app=myapp,rel=canary
# default             mage-app-dep467z4   1/1     Running   0          35h   app=mage-app-dep,pod-template-hash=74f6f6d8c6
# default             mage-app-dep5gl72   1/1     Running   0          35h   app=mage-app-dep,pod-template-hash=74f6f6d8c6

# 只显示某个字段 (-L field)：注意无需加 --show-labels，否则不生效
kc get pods -A -l 'app in (myapp,mage-app-dep)' -L app
# NAMESPACE                    NAME                            READY   STATUS    RESTARTS   AGE   APP
# clement-metadata-namespace   clement-metadata-name           1/1     Running   0          57m   myapp
# default                      mage-app-dep-74f6f6d8c6-467z4   1/1     Running   0          35h   mage-app-dep
# default                      mage-app-dep-74f6f6d8c6-5gl72   1/1     Running   0          35h   mage-app-dep

# 空 value 值：包含 key 即显示
kc get pods -A --show-labels -l 'app'
# NAMESPACE      NAME          READY   STATUS    RESTARTS   AGE    LABELS
# prod           myapp-prod    1/1     Running   0          77s    app=mageapp,rel=canary
# namespace      clement-name  1/1     Running   0          59m    app=myapp,rel=canary,tier=frontend
# default        mage-467z4    1/1     Running   0          35h    app=mage-app-dep,pod-template-hash=74f6f6d8c6
# kube-system    kube-flannel-ds-hpfgg           1/1     Running   0    3d4h   app=flannel,controller-revision-hash=7fb8b954f9,pod-template-generation=1,tier=node
```



### 资源注解

内嵌字段名：annotations

- 注解也是“键值″类型的数据，不过它不能用于标签及挑选 kubernetes对象，
- 仅用于为资源提供“元数据”信息
- 注解中的元数据不受字符数量的限制,它可大可小，可以为结构化或非结构化形式，
  也支持使用在标签中禁止使用的其他字符
- 在 kubernetes的新版本中( Alpha或Beta阶段)为某资源引入新字段时，
  常以注解方式提供以避免其增删等变动给用户带去困扰，
  一旦确定支持使用它们,这些新增字段再引入到资源中并淘汰相关的注解
- 很多 `pod` 或资源的管理软件，都会通过 `annotation` 来识别这个资源，甚至通过 `annotation` 来配置 `pod` 或其他资源。

```bash
kc describe pods myapp-prod -n prod
# Name:         myapp-prod
# Namespace:    prod
# Priority:     0
# Node:         node2/172.16.243.16
# Start Time:   Fri, 11 Jun 2021 16:32:33 +0800
# Labels:       app=mageapp
                rel=canary
# Annotations:  myk8s: mageapp		# k8s_v1.21.1中：只显示与上一版本不同处，v1.13中还会显示 apply 内容。
# Status:       Running
# IP:           10.244.2.16
# IPs:
#   IP:  10.244.2.16
```



























