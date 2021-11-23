## block 设备

### 块设备介绍

```bash
[root@centos8 ~]#  # b -> block # 块设备: nvme，sda，vda，
[root@centos8 ~]#  # nvme0     表示第一个插槽
[root@centos8 ~]#  # nvme0n1   表示第一块硬盘
[root@centos8 ~]#  # nvme0n1p1 表示第一块硬盘第一个分区(partition)
[root@centos8 ~]#  # nvme0n1p2 表示第一块硬盘第二个分区(partition)
[root@centos8 ~]# ll /dev/|grep brw
brw-rw---- 1 root disk    253,   0 10月  7 09:39 vda
brw-rw---- 1 root disk    253,   1 10月  7 09:39 vda1
[root@centos8 ~]# ll /dev/|grep brw
brw-rw---- 1 root disk    253,   0 10月  7 09:39 sda
brw-rw---- 1 root disk    253,   1 10月  7 09:39 sda1
在 Linux 系统中，SATA硬盘与SCSI硬盘都会被识别成 /dev/sd*。
IDE硬盘在早期 Linux 版本中，会被识别成 /dev/hd*。
```

### 文件系统扩容

```
扩容步骤：
加硬盘 -> 分区 -> 格式化(写入文件系统) -> 挂载(至目标目录)
通过命令行方式对磁盘进行分区(两种方式：MBR、GPT)
采用 MBR 方式进行分区就使用 fdisk 命令；
采用 GPT 方式进行分区就使用 gdisk 命令；(超过2T)
其他分区命令： parted
```

1. 手动创建分区（效率低）
2. 自动创建分区（有一定操作性）

```bash
# 查看当前所有磁盘的分区情况
[root@centos8 ~]# fdisk -l
Disk /dev/vda：20 GiB，21474836480 字节，41943040 个扇区
单元：扇区 / 1 * 512 = 512 字节
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：dos
磁盘标识符：0x8d959f3b
设备       启动  起点     末尾     扇区 大小 Id 类型
/dev/vda1  *     2048 41943039 41940992  20G 83 Linux

# 查看当前某块磁盘的分区情况
[root@centos8 ~]# fdisk -l /dev/vda1
Disk /dev/vda1：20 GiB，21473787904 字节，41940992 个扇区
单元：扇区 / 1 * 512 = 512 字节
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
```

#### fdisk

##### 手动扩展分区

```bash
欢迎使用 fdisk (util-linux 2.32.1)。
更改将停留在内存中，直到您决定将更改写入磁盘。
使用写入命令前请三思。
设备不包含可识别的分区表。
创建了一个磁盘标识符为 0x4967e4b2 的新 DOS 磁盘标签。
命令(输入 m 获取帮助)：m

帮助：
  DOS (MBR)
   a   开关 可启动 标志
   b   编辑嵌套的 BSD 磁盘标签
   c   开关 dos 兼容性标志
  常规
   d   删除分区
   F   列出未分区的空闲区
   l   列出已知分区类型
   n   添加新分区
   p   打印分区表
   t   更改分区类型
   v   检查分区表
   i   打印某个分区的相关信息
  杂项
   m   打印此菜单
   u   更改 显示/记录 单位
   x   更多功能(仅限专业人员)
  脚本
   I   从 sfdisk 脚本文件加载磁盘布局
   O   将磁盘布局转储为 sfdisk 脚本文件
  保存并退出
   w   将分区表写入磁盘并退出
   q   退出而不保存更改
  新建空磁盘标签
   g   新建一份 GPT 分区表
   G   新建一份空 GPT (IRIX) 分区表
   o   新建一份的空 DOS 分区表
   s   新建一份空 Sun 分区表
```

##### 自动扩展分区

```bash
[root@centos8 ~]# cat test
n
p
1
2048
     # (或留空保持默认)
w
[root@centos8 ~]# fdisk /dev/vdb < test
```

#### 创建文件系统

```bash
[root@centos8 ~]# mkfs.xfs /dev/vdb1
mkfs.cramfs  mkfs.ext2    mkfs.ext3    mkfs.ext4    mkfs.fat     mkfs.minix   mkfs.msdos   mkfs.vfat    mkfs.xfs
```

#### 文件系统扩容

```bash
留空
```

### 逻辑卷

```bash
pv(physical volume) # 物理卷：由多块物理硬盘组成的逻辑硬盘池 (磁盘损坏怎么办？)
vg(volume group)		# 卷组：  由物理硬盘池划分的可扩容分区卷组
lv(logical volume)	# 逻辑卷：算是写入文件系统？

```

#### 操作流程

##### pv的创建，pv的删除

```bash
创建
[root@centos8 ~]# pvcreate /dev/vdb{1..2}
  Physical volume "/dev/vdb1" successfully created.
  Physical volume "/dev/vdb2" successfully created.
删除
[root@centos8 ~]# pvremove /dev/vdb{1..2}
  Labels on physical volume "/dev/vdb1" successfully wiped.
  Labels on physical volume "/dev/vdb2" successfully wiped.
也可以整块添加
[root@centos8 ~]# pvremove /dev/vdc
```

##### vg的创建，vg的删除，vg的扩容

```bash
# 创建
[root@centos8 ~]# vgcreate vg1 /dev/vdb1
  Volume group "vg1" successfully created
# 查看
[root@centos8 ~]# vgs
  VG  #PV #LV #SN Attr   VSize  VFree
  vg1   1   0   0 wz--n- <4.00g <4.00g
# 也可以直接创建 vg: 当前版本 lvm2-8:2.03.11-5.el8.x86_64 可以自动创建 pv
[root@centos8 ~]# vgcreate vg2 /dev/vdb2
  Physical volume "/dev/vdb2" successfully created.
  Volume group "vg2" successfully created
# 扩容
[root@centos8 ~]# pvcreate /dev/vdb3  		# 扩容 pv 池
  Physical volume "/dev/vdb3" successfully created.
[root@centos8 ~]# vgextend vg2 /dev/vdb3	# 扩容卷组
  Volume group "vg2" successfully extended
[root@centos8 ~]# vgs
  VG  #PV #LV #SN Attr   VSize  VFree
  vg1   1   0   0 wz--n- <4.00g <4.00g
  vg2   2   0   0 wz--n-  5.99g  5.99g
```

##### 指定 PE SIZE

```bash
[root@centos8 ~]# vgcreate vg3 /dev/vdb5 -s 8M
  Physical volume "/dev/vdb5" successfully created.
  Volume group "vg3" successfully created
[root@centos8 ~]# vgs
  VG  #PV #LV #SN Attr   VSize    VFree
  vg1   1   0   0 wz--n-   <4.00g   <4.00g
  vg2   2   0   0 wz--n-    5.99g    5.99g
  vg3   1   0   0 wz--n- 1016.00m 1016.00m
[root@centos8 ~]# vgdisplay vg3
...
# 随着块增大空间利用率会变小
```

##### lv的创建，lv的删除，lv的扩容

```bash
# 创建
[root@centos8 ~]# lvcreate --name ams1 --size 300m vg1
  Logical volume "ams1" created.
[root@centos8 ~]# lvs
  LV   VG  Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ams1 vg1 -wi-a----- 300.00m
```



