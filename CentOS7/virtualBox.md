## centos7 安装 VirtualBox

### 安装 VirtualBox

新建 `/etc/yum.repos.d/virtualbox.repo`

```text
[virtualbox]
name=Virtualbox Repository
baseurl=https://mirrors.tuna.tsinghua.edu.cn/virtualbox/rpm/el$releasever/
gpgcheck=0
enabled=1
```

刷新缓存安装 VirtualBox

```
sudo yum makecache
sudo yum search VirtualBox
sudo yum install VirtualBox-6.1
```

### 安装 kernel driver

安装 编译工具

```bash
yum install gcc
```

进行编译

```bash
/sbin/vboxconfig
```

根据提示 安装 `kernel-devel`

```bash
yum install -y kernel-devel-3.10.0-xxx.el7.x86_64
 
# 如果常规找不到可以在以下网站搜索
http://rpm.pbone.net/resultsb_dist_95_size_17020072_name_kernel-devel-3.10.0-1062.el7.x86_64.rpm.html
```













