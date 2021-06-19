<!--
 * @Description:嗯, 你先玩
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-12-02 23:09:37
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-12-03 15:12:01
-->

| **角色** |        IP    |
|  :---:   |   :---:      |
|  master  | 192.168.11.141 |
|  node1   | 192.168.11.142 |
|  node2   | 192.168.11.143 |

###### 安装前初始化环境
```bash
# 关闭防火墙
[root@k8s-master ~]$ systemctl  stop    firewall
[root@k8s-master ~]$ systemctl  disable firewall

# 关闭 selinux
[root@k8s-master ~]$ sed -i 's/enforcing/disabled/' /etc/selinux/config  # 永久关闭
[root@k8s-master ~]$ setenforce 0 # 临时关闭

# 关闭swap
[root@k8s-master ~]$ swapoff -a
[root@k8s-master ~]$ sed -ri 's/.*swap.*/#&/' /etc/fstab

# 根据规划设置主机名
[root@k8s-master ~]$ hostnamectl set-hostname <hostname>

# 在master中添加hosts
[root@k8s-master ~]$ cat >> /etc/hosts << EOF
192.168.11.141 master
192.168.11.142 node1
192.168.11.143 node2
EOF

# 将桥接的ipv4流量传递到iptables的链
[root@k8s-master ~]$ cat  >  /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
[root@k8s-master ~]$ sysctl --system

# 时间同步
[root@k8s-master ~]$ sudo yum install -y ntpdate
[root@k8s-master ~]$ nptdate time.aliyun.com
```

#### 3.在所有节点中安装 docker/kubeadmin/kubelet
kubernetes 默认 CRI(容器运行时 container running) 为docker, 因此需要先安装docker

##### 3.1 安装docker
```bash
[root@k8s-master ~]$ wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
[root@k8s-master ~]$ yum install -y docker-ce-18.06.1.ce-3.el7
[root@k8s-master ~]$ systemctl enable docker-ce && systemctl start docker
[root@k8s-master ~]$ docker --version
# Docker version 18.06.1-ce, build e68fc7a
```
```bash
[root@k8s-master ~]$ cat > /etc/docker/daemon.json << EOF
# 为docker指定仓库镜像源
{
  "registry-mirrors": ["https://b9pmyelo.mirror.aliyuncs.com"]
}
EOF
[root@k8s-master ~]$ systemctl daemon-reload
[root@k8s-master ~]$ systemctl restart docker-ce.service
```
##### 3.2 添加阿里云 yum 软件源
```bash
[root@k8s-master ~]$ cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```
##### 3.3 安装kubeadm, kubelet和kubectl
```bash
# 由于版本更新频繁, 这里指定版本号部署:
[root@k8s-master ~]$ yum install -y kubelet-1.18.0 kubeadm-1.18.0 kubectl-1.18.0
[root@k8s-master ~]$ systemctl enable kubelet
```

#### 4.部署 Kubernetes Master
在 192.168.11.141 (Master中)执行
```bash
[root@k8s-master ~]$ kubeadm init\
--apiserver-advertise-address=192.168.11.141 \	# 指定api server
--image-repository registry.aliyuncs.com/google_containers \  # 指定拉取镜像仓库，可通过 kubeadm config images list 查看
--service-cidr=10.96.0.0/12 \  # 指定 service 网络
--pod-network-cidr=10.244.0.0/16 \ # 指定 pod 网络
--ignore-preflight-errors=Swap\		 # 指定忽略 已启用 swap 分区的错误
--dry-run \		# Don't apply any changes; just output what would be done.

# 会拉取几个镜像:
# kuber-proxy
# kube-apiserver
# kube-controller-manager
# kube-scheduler
# pause
# coredns
# etcd
```
由于默认拉取镜像地址 k8s.gcr.io 国内无法访问, 这里指定阿里云镜像仓库地址:
使用 kubectl 工具:
```bash
[root@k8s-master ~]$ mkdir -p $HOME/.kube
[root@k8s-master ~]$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[root@k8s-master ~]$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
[root@k8s-master ~]$ kubectl get nodes
```
#### 5.加入 Kubernetes Node
在 192.168.11.142, 192.168.11.143(Node中)执行.
向集群添加新节点, 执行在 kubeadm init 输出的kubeadm join 命令:
```bash
[root@k8s-master ~]$ kubeadm join 192.168.11.141:6443 --token esce21.q6hetwm8si29qxwn \
    --discovery-token-ca-cert-hash sha256: 00603a05805807501d7181c3d60b478788408cfe6cedefedb1f97569708be9c5
```
默认 token 有效期24小时, 当 token 过期时, 该 token 就不可用了. 这是需要重新创建 token, 操作如下:
```bash [root@k8s-master ~]$ kubeadm token create --print-join-command```

#### 6.部署CNI网络插件
```bash wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml```
默认镜像地址无法访问, sed 命令修改为 docker hub 镜像仓库
```bash
[root@k8s-master ~]$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

[root@k8s-master ~]$ kubectl get pods -n kube-system
NAME                            READY     STATUS    RESTARTS      AGE
kube-flannel-ds-amd64-2pc95     1/1       Running   0             72s
```
#### 7.测试 Kubernetes 集群
在 Kubernetes 集群中创建一个 pod, 验证是否能正常运行:
```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get pod, svc
```
访问地址:  http://NodeIP:Port
