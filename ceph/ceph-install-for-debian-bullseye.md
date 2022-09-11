

object store device - 磁盘管理
monitor             - 监控
metadata service    - 元数据（非必须）
mgr                 - 管理节点


## ceph install
ceph install for debian bullseye

### 集群拓扑

| 节点名      | cluster IP    | public IP      |
| ----------- | ------------- | -------------- |
| ceph-deploy | -             | 192.168.221.40 |
| ceph-1      | 192.168.222.2 | 192.168.221.41 |
| ceph-2      | 192.168.222.3 | 192.168.221.42 |
| ceph-3      | 192.168.222.4 | 192.168.221.43 |
| ceph-4      | 192.168.222.5 | 192.168.221.44 |




### 前置依赖
> 以下操作均需在每个节点执行！
> node、mgr、mon

**命令包**

```bash
# gnupg2: apt-key
# software-properties-common: apt-add-repository
root@ceph-1:~$ apt install -y software-properties-common gnupg2 python3-yaml sudo ansible
```

**安装ansible.utils**

```bash
# 在 ansible 执行节点安装
ansible-galaxy collection install ansible.utils
```

**为 ansible 配置代理**

```bash
# https://blog.csdn.net/qq_31977125/article/details/82796947
echo 'export http_proxy="http://10.10.221.101:20172" && export https_proxy="http://10.10.221.101:20172"' >> ~.bashrc
```

**hosts**

```conf
# 注意第一行 ceph-deploy 修改至对应主机名
127.0.0.1       localhost ceph-deploy
127.0.1.1       debian

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
192.168.221.40 ceph-deploy
192.168.221.41 ceph-1
192.168.221.42 ceph-2
192.168.221.43 ceph-3
192.168.221.44 ceph-4
``

**阿里云镜像站**
```bash
wget -q -O- 'https://mirrors.aliyun.com/ceph/keys/release.asc' | apt-key add - \
    && apt-add-repository 'deb https://mirrors.aliyun.com/ceph/debian-octopus/ buster main' \
    && apt update
```

**允许使用 https 源**
```bash
# docker 前置依赖
apt update && apt install -y apt-transport-https ca-certificates curl software-properties-common
```

**创建用户（ansible用户可不用）**

```bash
# ubuntu/deian
groupadd -r -g 2088 cephadmin && useradd -r -m -s /bin/bash -u 2088 -g 2088 cephadmin && echo cephadmin:123456 | chpasswd

# centos
groupadd -g 2088 cephadmin && useradd -m -s /bin/bash -u 2088 -g 2088 cephadmin && echo "123456" | passwd --stdin ceph
```

**允许 cephadmin 使用sudo （ansible用户可不用）**

```bash
#vim /etc/sudoers
root ALL=(ALL)  ALL
ceph ALL=(ALL)  NOPASSWD:ALL

#或者
echo "cephadmin ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers
```

**用户 cephadmin 配置免密登录**

略，但必备

**配置 all.yml 文件**

详细见 all.yml 注解，部分设置存在于 group_vars 目录内其余文件，更多说明见文件内注解。

```yaml
---
dummy:
mon_group_name: mons
osd_group_name: osds
mds_group_name: mdss
client_group_name: clients
mgr_group_name: mgrs
configure_firewall: False
ceph_origin: repository
ceph_repository: community
ceph_mirror: https://mirrors.aliyun.com/ceph
ceph_stable_key: https://mirrors.aliyun.com/ceph/keys/release.asc
ceph_stable_release: pacific
ceph_stable_repo: "{{ ceph_mirror }}/debian-{{ ceph_stable_release }}"
cephx: true
copy_admin_key: true
monitor_interface: ens33
monitor_address_block: subnet
ip_version: ipv4
# 对客户端/k8s/挂载方，提供服务的接口
public_network: 192.168.222.0/0
# 下载、安装、同步维护集群接口，ansible 会改 DNS ，如果没有公网会下载失败。
cluster_network: 192.168.221.0/0
osd_objectstore: bluestore
osd_auto_discovery: true
```

复制 mon、osd、mgr、mds的 yaml 文件，保持 dummy 变量存在。

```bash
# 在group_vars 目录下执行
for i in {all,mons,osds,mgrs,mdss};do cp $i.yml.sample $i.yml;done
```

在 `group_vars` 的上一级目录，即 ceph-ansible 目录的根目录下，新建一个 hosts 文件，作为 ansible 的资产清单使用。

```hosts
[mons]
192.168.221.41
192.168.221.42
192.168.221.43
[mgrs]
192.168.221.41
192.168.221.42
192.168.221.43
[mdss]
192.168.221.41
192.168.221.42
192.168.221.43
[osds]
192.168.221.41
192.168.221.42
192.168.221.43
192.168.221.44
[clients]
192.168.221.40
[monitoring]
192.168.221.50
```



### 单独指明 DB和 WAL设备

指明 block-db 设备

编辑 group_vars/osds.yml，添加 （在all.yml中添加也行）

```yaml
dedicated_devices:
  - /dev/sdg
```

编辑 group_vars/all.yml，添加 

```yaml
# 如果有多个设备，在此处全部写好，表示在做 osd 设备自动发现时，将这些设备排除。
osd_auto_discovery_exclude: "dm-*|loop*|md*|rbd*|sdg"
```

指明 block-wal 设备

```yaml
bluestore_wal_devices:
  - /dev/nvme0n1
```

编辑 group_vars/all.yml，添加 

```yaml
# 如果有多个设备，在此处全部写好，表示在做 osd 设备自动发现时，将这些设备排除。
osd_auto_discovery_exclude: "dm-*|loop*|md*|rbd*|nvme0n1"
```













