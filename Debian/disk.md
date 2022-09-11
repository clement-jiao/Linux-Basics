## 磁盘扩容

适用于：VMware 等虚拟机中Debian 11 的磁盘扩容

大体步骤可参考阿里云ecs 磁盘扩容文档，防止再翻文档在下面重新写一遍步骤

[离线扩容云盘（Linux系统） (aliyun.com)](https://help.aliyun.com/document_detail/44986.html)



### 安装 growpart 工具。

Debian 8及以上版本、Ubuntu14及以上版本运行以下命令

```bash
apt update
apt-get install -y cloud-guest-utils

# 安装之前可查询是否有这个安装包
root@debian:~# apt-cache madison cloud-guest-utils 
cloud-guest-utils |     0.31-2 | http://mirrors.ustc.edu.cn/debian bullseye/main amd64 Packages
cloud-utils |     0.31-2 | http://mirrors.ustc.edu.cn/debian bullseye/main Sources

```

### 关闭并删除 swap 及多余分区 ( 仅保留主分区 )

**扩容分区前需先确认是否有扩展分区及swap分区，如果有则需删除，**

**如不删除轻则开机启动时无法加载swap分区 `导致开机缓慢`，重则 swap 分区数据被删除引起`系统崩溃`。**

```bash
# 查看是否有 swap 分区
# 1. 内存查询
root@debian:~$ swapoff -a

# 验证：
root@debian:~$ free -h
           total        used        free      shared  buff/cache   available
内存：      7.8Gi       238Mi       7.2Gi       0.0Ki       320Mi       7.3Gi
交换：         0B          0B          0B
root@debian:~$ lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0    1T  0 disk 
└─sda1   8:1    0 1024G  0 part /
sr0     11:0    1 1024M  0 rom 

```

#### 删除 /etc/fstab 的 swap 启动分区

```bash
# vim /etc/fstab
# swap was on /dev/sda5 during installation
# UUID=0f99f0e6-f827-4f83-a1d1-5e5de77ce1f4 none            swap    sw              0       0
```

#### 删除其余分区

```bash
fdisk /dev/sda
d 5
d 2
w

# 删除分区后 重启系统校验是否有错误。
```



### 扩容分区。

```bash
# 示例命令表示扩容系统盘的第一个分区，
# /dev/vda是系统盘，1是分区编号，/dev/vda和1之间需要空格分隔。

# 若不删除其余分区，此步骤会报错：仅能扩展至 2046 扇区。

growpart /dev/vda 1
```

### 扩容文件系统

```bash
# ext4 使用 resizfs 扩容文件系统，xfs 见官方文档。
resize2fs /dev/vda1
```

扩容后检查扩容结果

```bash
root@debian:~$ df -Th
文件系统       类型      容量  已用  可用 已用% 挂载点
udev           devtmpfs  3.9G     0  3.9G    0% /dev
tmpfs          tmpfs     796M  908K  795M    1% /run
/dev/sda1      ext4     1007G  2.1G  962G    1% /
tmpfs          tmpfs     3.9G     0  3.9G    0% /dev/shm
tmpfs          tmpfs     5.0M     0  5.0M    0% /run/lock
tmpfs          tmpfs     796M     0  796M    0% /run/user/

root@debian:~$ lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0    1T  0 disk 
└─sda1   8:1    0 1024G  0 part /
sr0     11:0    1 1024M  0 rom  
```

#### 将扩容后的磁盘ID 同步至内核

```bash
# 获取新磁盘分区 UUID 

blkid  /dev/sdb1

# 修改 /etc/fstab 中 swap 分区的 UUID。
# 修改 /etc/initramfs-tools/conf.d/resume 中的 UUID
vim /etc/initramfs-tools/conf.d/resume

# 然后执行,同步至所有内核。
sudo update-initramfs -u -k all
```

**结束**

### 参考资料

[离线扩容云盘（Linux系统） (aliyun.com)](https://help.aliyun.com/document_detail/44986.html)

[解决Linux启动缓慢：Gave up waiting for suspend/resume device](https://blog.csdn.net/hardwork617s/article/details/121055169)

[give up waiting for suspend/resume device的问题](https://www.cnblogs.com/panther1942/p/12752073.html)
