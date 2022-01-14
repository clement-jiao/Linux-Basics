<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-12-03 10:13:56
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-12-03 16:38:19
-->

### 二进制安装k8s

### 1.创建多台虚拟机, 安装操作系统(内核在3.1以上)
| **角色** |        IP    |
|  :---:   |   :---:      |
|  master  | 192.168.11.151 |
|  node1   | 192.168.11.152 |
### 2.操作系统初始化
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
[root@k8s-node1  ~]$ hostnamectl set-hostname <hostname>

# 在master中添加hosts
[root@k8s-master ~]$ cat >> /etc/hosts << EOF
192.168.11.151 master
192.168.11.152 node1
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
### 3.为etcd和APIserver自签证书
##### 3.1准备cfssl证书生产工具
cfssl 是一个开源的证书管理工具, 使用 json 文件生成证书, 相比 OpenSSL 更方便使用.
```bash
[root@k8s-master ~]$ wget http://pkg.cfssl.org/R1.2/cfssl_linux-amd64
[root@k8s-master ~]$ wget http://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
[root@k8s-master ~]$ wget http://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
[root@k8s-master ~]$ chmod +x cfssl_linux_amd64 cfssljson_linux_amd64 cfssl-certinfo_linux_amd64
[root@k8s-master ~]$ mv cfssl_linux_amd64 /usr/local/bin/cfssl
[root@k8s-master ~]$ mv cfssljson_linux_amd64 /usr/local/bin/cfssljson
[root@k8s-master ~]$ mv cfssl-certinfo_linux_amd64 /usr/local/bin/cfssl-certinfo

# 缩减为脚本操作
[root@k8s-master ~]$ cat /cfssl.sh
# curl -L http://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl
# curl -L http://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson
# curl -L http://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o /usr/local/bin/cfssl-certinfo
cp -rf cfssl cfssljson cfssl-certinfo /usr/local/bin/
chmod +x /usr/local/bin/cfssl*

# cfssl执行脚本
[root@k8s-master ~]$ cat generate_etcd_cert.sh
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
```

##### 生成 Etcd 证书
自签证书颁发机构(CA)

创建工作目录
```bash
[root@k8s-master ~]$ mkdir ~/TLS/{etcd,k8s}
[root@k8s-master ~]$ cd TLS/etcd
```

生成CA配置文件
```bash
[root@k8s-master ~]$ cat > ca-config.json << EOF
{
  "signing": {
  "default":{
    "expiry": "87600h"
  },
  "profiles": {
    "www": {
      "expiry": "87600h",
      "usages": [
        "signing",
        "key encipherment",
        "server auth",
        "client auth"
        ]
      }
    }
  }
}
EOF

[root@k8s-master ~]$ cat > ca-csr.json << EOF
{
  "CN": "etcd CA",
  "key": {
    "algo": "rsa",
    "size": 2048
    },
    "name": [
      {
        "C": "CN",
        "L": "Beijing",
        "ST" : "Beijing"
      }
    ]
}
EOF
```

自签CA证书:
```bash
# 生成ca文件:
[root@k8s-master ~]$ cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
[root@k8s-master ~]$ ls *.pem
ca-key.pem ca.pem

[root@k8s-master ~]$ ls
ca-config.json ca.csr ca-csr.json ca-key.pem ca.pem generate_etcd_cert.sh server-csr.json

# 修改 server-csr.json 文件
# 注意以下 hosts 字段中 IP 为所有 etcd 节点的集群内部通信 IP, 一个都不能少!
# 为了方便后期扩容可以多些几个预留的IP.
[root@k8s-master ~]$ cat server-csr.json
{
    "CN":"etcd",
    "hosts":[
        "192.168.11.151",
        "192.168.11.152"
    ],
    # 注意不能有多余逗号(未验证)
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L":"Beijing",
            "ST":"Beijing"
        }
    ]
}

# 生成证书文件
[root@k8s-master ~]$ cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
-config=ca-config.json -profile=www server-csr.json | cfssljson -bare server

# 查看生成证书文件
[root@k8s-master ~]$ ls
ca-config.json ca.csr ca-csr.json ca-key.pem ca.pem generate_etcd_cert.sh
server-csr.json server-key.pem server.pem

# 查看pem文件
[root@k8s-master ~]$ ls *.pem
ca-key.pem ca.pem server-csr.json server-key.pem server.pem
```

### 4.部署etcd集群
Etcd 是一个分布式键值存储系统, Kubernetes 使用 Etcd 进行数据存储, 所以先准备一个 Etcd 数据库,为了解决 Etcd 单点故障, 应采用集群方式部署,这里使用3台组建集群, 可容忍1台机器故障,若使用5台组建集群,则可容忍2台机器故障(**有点类似raid5**)

##### 节点介绍
为了节省资源, 这里可以与k8s节点机器复用. 也可以独立于k8s集群之外部署, 只要apiserver可以连接到就可以
| **节点名称** |       IP       |
|    :---:     |     :---:      |
|    etcd-1    | 192.168.11.151 |
|    etcd-1    | 192.168.11.152 |

从 GitHub 下载 etcd 二进制执行文件
[http://github.com/etcd-io/etcd/releases/download/v3.4.9/etcd-v3.4.9-linux-amd64.tar.gz](http://github.com/etcd-io/etcd/releases/download/v3.4.9/etcd-v3.4.9-linux-amd64.tar.gz)

### 5.部署master组件
### 6.部署node组件
### 7.部署集群网络

