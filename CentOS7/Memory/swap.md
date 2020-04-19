<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-04-06 00:22:26
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-04-06 00:31:59
 -->

### 在阿里云ECS中构建SWAP分区

#### 简介：
swap交换空间实际上是一个磁盘分区，在安装操作系统时，默认划分出物理内存的1~2倍空间用于交换分区，它类似于 Windows 的虚拟内存。系统会把一部分硬盘空间虚拟成内存使用，将系统内非活动内存换页到 SWAP，以提高系统可用内存。

#### 阿里云ECS的swap:
阿里云ECS服务器的swap功能默认时没有开启的，因为swap功能会增加磁盘IO的占用率，降低磁盘寿命和性能，另一方面也可以借此让用户购买更大的内存。启用swap分区，一定程度上可以降低物理内存的使用压力，但如果云服务器上运行的应用确实需要更多的内存，还是需要购买物理内存。

#### 一、查看是否启用swap分区
1. free -m
2. cat /proc/swaps

#### 二、如果未启用swap分区功能，则新建一个专门的文件用于swap分区

`dd if=/dev/zero of=/mnt/swap bs=block_size count=number_of_block`

>注：block_size、number_of_block 大小可以自定义，比如 bs=1M/1G count=1024/1 代表设置 1G 大小 SWAP 分区

#### 三、设置交换分区文件

通过mkswap命令将上面新建出的文件做成swap分区

`mkswap /mnt/swap`

>注：mkswap时如果出现如下错误，是因为SWAP 文件太小，SWAP 文件至少应该大于 40KB，重新执行上一步骤生成更大的文件即可
mkswap: error: swap area needs to be at least 40 KiB


#### 四、修改内核参数 /proc/sys/vm/swappiness

当 swappiness为 0 时，表示最大限度的使用物理内存，物理内存使用完毕后，才会使用 SWAP 分区；
当 swappiness 为 100 时，表示积极地使用 SWAP 分区，并且把内存中的数据及时地置换到 SWAP 分区。

根据实际需要设置该值即可,如下述方法临时修改此参数，假设我们配置为空闲内存少于 30% 时才使用 SWAP 分区

`# echo 30 >/proc/sys/vm/swappiness`

若需要永久修改此配置，在系统重启之后也生效，可修改 /etc/sysctl.conf 文件，增加以下内容

```bash
# vim /etc/sysctl.conf
vm.swappiness=30
sysctl -p

# sysctl vm.swappiness=30
# 等同于上一条命令
```
#### 五、启用此交换分区的交换功能

`swapon /mnt/swap`

>注意：如果在 /etc/rc.local 中有 swapoff -a 需要修改为 swapon -a
**mkswap后需要swapon来启用分区!**

#### 六、设置开机时自启用 SWAP 分区

修改文件 /etc/fstab 中的 SWAP 行，添加一行/mnt/swap swap swap defaults 0 0
`echo "/mnt/swap swap swap defaults 0 0" >> /etc/fstab`

#### 七、检查是否设置成功

```bash
# cat /proc/swaps
# free -m
```



8、关闭swap分区
当系统出现内存不足时，开启 SWAP 可能会因频繁换页操作，导致 IO 性能下降。如果要关闭 SWAP，可以采用如下方法。
使用命令 swapoff 关闭 SWAP

修改 /etc/fstab 文件，删除或注释相关配置，取消 SWAP 的自动挂载#swapoff /mnt/swap

`#swapoff -a >/dev/null`
