## 通过 Kubeasz 安装 k8s 集群

知识要点整理：盲猜有很多坑点没有踩到以后慢慢更新

https://www.cnblogs.com/linuxk/p/10762832.html

## Kubeasz

[easzlab/kubeasz(github.com)](https://github.com/easzlab/kubeasz)

使用Ansible脚本安装K8S集群，介绍组件交互原理，方便直接，不受国内网络环境影响。

注意：3.2.0 以上版本将改用 containerd，如果继续使用 docker 需要另配置。（未研究）

> 修改默认容器运行时为 containerd，如果需要仍旧使用docker，请对应修改clusters/${集群名}/hosts 配置项`CONTAINER_RUNTIME`

### 环境配置

三节点高可用集群，内存不够的用单节点，基础镜像为512M，需要更改的在以下表格中注明，最后整体下来约为5G左右。

基础镜像：Debian 11 + 免秘 + docker + docker-compose

|           角色            |      IP       |
| :-----------------------: | :-----------: |
|       k8s-master-1        | 192.168.11.11 |
|       k8s-master-2        | 192.168.11.12 |
|       k8s-master-3        | 192.168.11.15 |
|        k8s-node-1         | 192.168.11.19 |
|        k8s-node-2         | 192.168.11.20 |
|        k8s-node-3         | 192.168.11.21 |
|        k8s-etcd-1         | 192.168.11.16 |
|        k8s-etcd-2         | 192.168.11.17 |
|        k8s-etcd-3         | 192.168.11.18 |
|       k8s-HA-master       | 192.168.11.10 |
|       k8s-HA-backup       | 192.168.11.13 |
| k8s-harbor (至少需要1.5G) | 192.168.11.14 |

## k8s-harbor

[harbor](../k8s周边/harbor/harbor.md)

高可用：[harbor_HA](../k8s周边/harbor/harbor_HA.md)

## k8s-HA

[keepalived + haproxy](../k8s周边/HA/keepalived+haproxy.md)

## k8s-master-1

**跟着下面的文档一步一步走就好**

[kubeasz/00-planning_and_overall_intro.md(github.com)](https://github.com/easzlab/kubeasz/blob/master/docs/setup/00-planning_and_overall_intro.md)

```bash
# 2.系统更新：  
`apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y`

# 3.1 安装 ansible 
`apt install -y ansible`

# 3.2 配置免秘
# 更安全 Ed25519 算法
`ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519`
# 或者传统 RSA 算法
`ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa`
`ssh-copy-id $IPs` #$IPs为所有节点地址包括自身，按照提示输入yes 和root密码

# 3.3 为每个节点设置python软链接
`ssh $IPs ln -s /usr/bin/python3 /usr/bin/python`

# 4.1 下载工具脚本ezdown，举例使用kubeasz版本3.0.0
export release=3.1.1
wget https://github.com/easzlab/kubeasz/releases/download/${release}/ezdown
chmod +x ./ezdown
# 使用工具脚本下载
./ezdown -D
```

### ezdown 说明

```bash
root@k8s-master-1:/etc/kubeasz$ ./ezctl -hj
Usage: ezctl COMMAND [args]
-------------------------------------------------------------------------------------
Cluster setups:
    list		                     to list all of the managed clusters
    checkout    <cluster>            to switch default kubeconfig of the cluster
    new         <cluster>            to start a new k8s deploy with name 'cluster'
    setup       <cluster>  <step>    to setup a cluster, also supporting a step-by-step way
    start       <cluster>            to start all of the k8s services stopped by 'ezctl stop'
    stop        <cluster>            to stop all of the k8s services temporarily
    upgrade     <cluster>            to upgrade the k8s cluster
    destroy     <cluster>            to destroy the k8s cluster
    backup      <cluster>            to backup the cluster state (etcd snapshot)
    restore     <cluster>            to restore the cluster state from backups
    start-aio		          to quickly setup an all-in-one cluster with 'default' settings

Cluster ops:
    add-etcd    <cluster>  <ip>      to add a etcd-node to the etcd cluster
    add-master  <cluster>  <ip>      to add a master node to the k8s cluster
    add-node    <cluster>  <ip>      to add a work node to the k8s cluster
    del-etcd    <cluster>  <ip>      to delete a etcd-node from the etcd cluster
    del-master  <cluster>  <ip>      to delete a master node from the k8s cluster
    del-node    <cluster>  <ip>      to delete a work node from the k8s cluster

Extra operation:
    kcfg-adm    <cluster>  <args>    to manage client kubeconfig of the k8s cluster
Use "ezctl help <command>" for more information about a given command.
```

### 自定义集群配置文件

```bash
root@k8s-master-1:/etc/kubeasz$ ./ezctl new clemente_cluster01

DEBUG generate custom cluster files in /etc/kubeasz/clusters/clemente_cluster01
DEBUG set version of common plugins
DEBUG disable registry mirrors
DEBUG cluster clemente_cluster01: files successfully created.
INFO next steps 1: to config '/etc/kubeasz/clusters/clemente_cluster01/hosts'
INFO next steps 2: to config '/etc/kubeasz/clusters/clemente_cluster01/config.yml'

# 集群配置路径：/etc/kubeasz/clusters/clemente_cluster01
# 拷贝的模板路径：/etc/kubeasz/example
```

#### hosts 文件

```bash
# vim /etc/kubeasz/clusters/clemente_cluster01/hosts
# 需要注意修改的地方：
# etcd
# master node
# work node
# harbor
# ex_lb : 注意 第一行backup，第二行master。目标端口、rip与vip不要混
# CONTAINER_RUNTIME：docker 与 containerd
# CLUSTER_NETWORK：calico, flannel。还有其他组件上面有说明
# Service CIDR, Cluster CIDR 酌情修改
# NodePort Range：可能会通过 .service 文件来限制吧
# Binaries Directory：放到 /usr/bin/ 目录下，可以全局访问
```

#### config 文件

```bash
# vim /etc/kubeasz/clusters/clemente_cluster01/config.yml
# 需要注意修改的地方：
CA_EXPIRY: "876000h"
CERT_EXPIRY: "438000h"

# 设置不同的wal目录，可以避免磁盘io竞争，提高性能
ETCD_DATA_DIR: "/var/lib/etcd"
ETCD_WAL_DIR: ""

# [.]启用容器仓库镜像
ENABLE_MIRROR_REGISTRY: true

# [docker]信任的HTTP仓库
INSECURE_REG: '["127.0.0.1/8","192.168.11.14"]'

# k8s 集群 master 节点证书配置，可以添加多个ip和域名（比如增加公网ip和域名）
MASTER_CERT_HOSTS:
  - "10.1.1.1"
  - "k8s.test.io"
  #- "www.test.com"

# node节点最大pod 数
MAX_PODS: 110 -> 400

# [calico]设置 CALICO_IPV4POOL_IPIP=“off”,可以提高网络性能，条件限制详见 docs/setup/calico.md
CALICO_IPV4POOL_IPIP: "Always"

# 附加组件默认会自动安装
# coredns 自动安装
dns_install: "no" 
ENABLE_LOCAL_DNS_CACHE: false

# metric server 自动安装
metricsserver_install: "no"

# dashboard 自动安装
dashboard_install: "no" 

# 其余默认
```

### 分步安装

回到基础目录： `cd /etc/kubeasz/`

```bash
root@k8s-master-1:/etc/kubeasz$ ./ezctl setup --help
Usage: ezctl setup <cluster> <step>
available steps:
    01  prepare            to prepare CA/certs & kubeconfig & other system settings 
    02  etcd               to setup the etcd cluster
    03  container-runtime  to setup the container runtime(docker or containerd)
    04  kube-master        to setup the master nodes
    05  kube-node          to setup the worker nodes
    06  network            to setup the network plugin
    07  cluster-addon      to setup other useful plugins
    90  all                to run 01~07 all at once
    10  ex-lb              to install external loadbalance for accessing k8s from outside
    11  harbor             to install a new harbor server or to integrate with an existed one

# examples: ./ezctl setup test-k8s 01  (or ./ezctl setup test-k8s prepare)
# 	        ./ezctl setup test-k8s 02  (or ./ezctl setup test-k8s etcd)
#           ./ezctl setup test-k8s all
#           ./ezctl setup test-k8s 04 -t restart_master
```

#### step 01  初始化系统

```bash
# ./ezctl setup [cluster_name] [steps]
# 初始化集群证书、参数和优化相关配置等。
# 启动后约有5秒的贤者时间。其中会禁用 swap 分区，注意子节点的内存使用情况
root@k8s-master-1:/etc/kubeasz$ ./ezctl setup clemente_cluster01 01

```

#### step 02 安装 etcd

```bash
#  初始化系统完成后在开始部署 etcd 服务
root@k8s-master-1:/etc/kubeasz# ./ezctl setup clemente_cluster01 02

# ssh 192.168.11.16
root@k8s-etcd-1:~$ systemctl status etcd
● etcd.service - Etcd Server
     Loaded: loaded (/etc/systemd/system/etcd.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2022-01-14 03:20:49 CST; 3min 38s ago
       Docs: https://github.com/coreos
   Main PID: 5184 (etcd)
      Tasks: 10 (limit: 489)
     Memory: 27.3M
        CPU: 2.879s
     CGroup: /system.slice/etcd.service
             └─5184 /usr/bin/etcd --name=etcd-192.168.11.16 --cert-file=/etc/kubernetes/ssl/etcd.pem --key-file=/etc/kubernetes/ssl/etcd-key.pem --peer-cert-
...
# 更多参数可查看 /etc/systemd/system/etcd.service
```

##### 验证 etcd 服务：

```bash
# 需要注意以下证书的路径
root@k8s-etcd-1:~$ export NODE_IPS="192.168.11.16 192.168.11.17 192.168.11.18"
root@k8s-etcd-1:~$ for ip in ${NODE_IPS};do  ETCDCTL_API=3 /usr/bin/etcdctl  \
--endpoints=https://${ip}:2379 \
--cacert=/etc/kubernetes/ssl/ca.pem \
--cert=/etc/kubernetes/ssl/etcd.pem  \
--key=/etc/kubernetes/ssl/etcd-key.pem endpoint health; done

https://192.168.11.16:2379 is healthy: successfully committed proposal: took = 14.44038ms
https://192.168.11.17:2379 is healthy: successfully committed proposal: took = 10.750738ms
https://192.168.11.18:2379 is healthy: successfully committed proposal: took = 10.285031ms
```

#### step 03 安装 docker

```bash
# 正常安装 docker，别有其他版本 docker 或 containerd 就好
root@k8s-master-1:/etc/kubeasz$ ./ezctl setup clemente_cluster01 03
```

#### step 04 安装 master

```bash
# 注意master节点至少需要1G内存，否则会 oom。
root@k8s-master-1:/etc/kubeasz$ ./ezctl setup clemente_cluster01 04
```

#### step 05 安装 node

```bash
root@k8s-master-1:/etc/kubeasz$ ./ezctl setup clemente_cluster01 05
```

##### 验证 node 节点

```bash
root@k8s-master-1:/etc/kubeasz# kubectl get nodes
NAME            STATUS                     ROLES    AGE   VERSION
192.168.11.11   Ready,SchedulingDisabled   master   27m   v1.22.2
192.168.11.12   Ready,SchedulingDisabled   master   15m   v1.22.2
192.168.11.19   Ready                      node     74s   v1.22.2
192.168.11.20   Ready                      node     73s   v1.22.2
```

#### step 06 安装 calico 

```bash
# ezdown 会提前下好 calico 离线镜像，如果没有离线镜像会去 docker.io 去下载
# 确认 /etc/kubeasz/down 目录有离线镜像后，会从master-1向其他节点推送该镜像
root@k8s-master-1:/etc/kubeasz$ ./ezctl setup clemente_cluster01 06
```

##### 验证

```bash
# calicoctl命令行工具用于管理Calico网络和安全策略，查看和管理端点配置，以及管理Calico节点实例。
root@k8s-master-1:/etc/kubeasz/down$ calicoctl node --help
Set the Calico datastore access information in the environment variables or
supply details in a config file.
Usage:
  calicoctl node <command> [<args>...]
    run          Run the Calico node container image.
    status       View the current status of a Calico node.
    diags        Gather a diagnostics bundle for a Calico node.
    checksystem  Verify the compute host is able to run a Calico node instance.

# calicoctl 查看各节点连接状态
root@k8s-master-1:/etc/kubeasz/down$ calicoctl node status
Calico process is running.
IPv4 BGP status
+---------------+-------------------+-------+----------+-------------+
| PEER ADDRESS  |     PEER TYPE     | STATE |  SINCE   |    INFO     |
+---------------+-------------------+-------+----------+-------------+
| 192.168.11.20 | node-to-node mesh | up    | 20:29:19 | Established |
| 192.168.11.19 | node-to-node mesh | up    | 20:29:20 | Established |
| 192.168.11.12 | node-to-node mesh | up    | 20:29:20 | Established |
+---------------+-------------------+-------+----------+-------------+
IPv6 BGP status
No IPv6 peers found.
```

### 验证安装后的k8s

#### 容器 pending

启动 pod 后一直处于 pending 状态

```bash
root@k8s-master-1:~$ kubectl run net-test1 --image=containous/whoami --port=80
root@k8s-master-2:~$ kubectl get pods -A 
NAMESPACE     NAME                                       READY   STATUS    RESTARTS      AGE
default       net-test1                                  0/1     Pending   0             10m
...

# 此时发现 pod 一直在 pending
# 查看此 pod 详细信息，发现 node 节点有内存压力：node.kubernetes.io/memory-pressure，添加内存即可
root@k8s-master-1:~$ kubectl describe pod net-test1 -n default
...
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  11m   default-scheduler  0/4 nodes are available: 2 node(s) had taint {node.kubernetes.io/memory-pressure: }, that the pod didn't tolerate, 2 node(s) were unschedulable.
...
```

#### 知识要点

```bash
# 基于污点的驱逐 
# 当某种条件为真时，节点控制器会自动给节点添加一个污点。当前内置的污点包括：
node.kubernetes.io/not-ready：   节点未准备好。这相当于节点状态 Ready 的值为 "False"。
node.kubernetes.io/unreachable： 节点控制器访问不到节点. 这相当于节点状态 Ready 的值为 "Unknown"。
node.kubernetes.io/memory-pressure：节点存在内存压力。
node.kubernetes.io/disk-pressure：  节点存在磁盘压力。
node.kubernetes.io/pid-pressure:   节点的 PID 压力。
node.kubernetes.io/network-unavailable：节点网络不可用。
node.kubernetes.io/unschedulable:       节点不可调度。
node.cloudprovider.kubernetes.io/uninitialized：
# 如果 kubelet 启动时指定了一个 "外部" 云平台驱动， 它将给当前节点添加一个污点将其标志为不可用。在 cloud-controller-manager 的一个控制器初始化这个节点后，kubelet 将删除这个污点。
```



