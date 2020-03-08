<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-18 17:08:00
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-20 15:33:03
 -->
#CentOS 7 下 yum 安装和配置 NFS

##简介
NFS 是 Network File System 的缩写，即网络文件系统。功能是让客户端通过网络访问不同主机上磁盘里的数据，主要用在类Unix系统上实现文件共享的一种方法。 本例演示 CentOS 7 下安装和配置 NFS 的基本步骤。

###环境说明
CentOS 7（Minimal Install）
```bash
$ cat /etc/redhat-release
CentOS Linux release 7.5.1804 (Core)
```

>根据官网说明 Chapter 8. Network File System (NFS) - Red Hat Customer Portal，CentOS 7.4 以后，支持 NFS v4.2 不需要 rpcbind 了，但是如果客户端只支持 NFC v3 则需要 rpcbind 这个服务。

##服务端
###服务端安装
  使用 yum 安装 NFS 安装包。

  ```bash
  yum install nfs-utils
  ```

  >注意：只安装 nfs-utils 即可，rpcbind 属于它的依赖，也会安装上。

###服务端配置
  - 设置 NFS 服务开机自启并启动
    ```bash
    $ sudo systemctl enable --now rpcbind
    $ sudo systemctl enable --now nfs
    ```

  - 防火墙需要打开 rpc-bind 和 nfs 的服务
    ```bash
    $ sudo firewall-cmd --zone=public --permanent --add-service=rpc-bind
    success
    $ sudo firewall-cmd --zone=public --permanent --add-service=mountd
    success
    $ sudo firewall-cmd --zone=public --permanent --add-service=nfs
    success
    $ sudo firewall-cmd --reload
    success
    ```

###配置共享目录
  - 服务启动之后，在服务端配置共享目录
    ```bash
    mkdir /data
    chmod 755 /data
    ```

  - 根据这个目录，相应配置导出目录
    ```bash
    vi /etc/exports
    ```
  - 添加如下配置
    ```conf
    # vim /etc/exports
    /data/     192.168.0.0/24(rw,sync,no_root_squash,no_all_squash)
    ```

    1. /data: 共享目录位置。
    2. 192.168.0.0/24: 客户端 IP 范围，* 代表所有，即没有限制。
    3. rw: 权限设置，可读可写。
    4. sync: 同步共享目录。
    5. no_root_squash: 可以使用 root 授权。
    5. no_all_squash: 可以使用普通用户授权。
    `:wq 保存设置之后，重启 NFS 服务。`

    ```bash
    # 192.168.0.0/24 可以为一个网段，一个IP，也可以是域名，域名支持通配符 如: *.com
    # rw：read-write，可读写；
    # ro：read-only，只读；
    # sync：文件同时写入硬盘和内存；
    # async：文件暂存于内存，而不是直接写入内存；
    # no_root_squash：NFS客户端连接服务端时如果使用的是root的话，那么对服务端分享的目录来说，也拥有root权限。显然开启这项是不安全的。
    # root_squash：NFS客户端连接服务端时如果使用的是root的话，那么对服务端分享的目录来说，拥有匿名用户权限，通常他将使用nobody或nfsnobody身份；
    # all_squash：不论NFS客户端连接服务端时使用什么用户，对服务端分享的目录来说都是拥有匿名用户权限；
    # anonuid：匿名用户的UID值
    # anongid：匿名用户的GID值。备注：其中anonuid=1000,anongid=1000,为此目录用户web的ID号,达到连接NFS用户权限一致。
    # defaults 使用默认的选项。默认选项为rw、suid、dev、exec、auto nouser与async。
    # atime 每次存取都更新inode的存取时间，默认设置，取消选项为noatime。
    # noatime 每次存取时不更新inode的存取时间。
    # dev 可读文件系统上的字符或块设备，取消选项为nodev。
    # nodev 不读文件系统上的字符或块设备。
    # exec 可执行二进制文件，取消选项为noexec。
    # noexec 无法执行二进制文件。
    # auto 必须在/etc/fstab文件中指定此选项。执行-a参数时，会加载设置为auto的设备，取消选取为noauto。
    # noauto 无法使用auto加载。
    # suid 启动set-user-identifier设置用户ID与set-group-identifer设置组ID设置位，取消选项为nosuid。
    # nosuid 关闭set-user-identifier设置用户ID与set-group-identifer设置组ID设置位。
    # user 普通用户可以执行加载操作。
    # nouser 普通用户无法执行加载操作，默认设置。
    # remount 重新加载设备。通常用于改变设备的设置状态。
    # rsize 读取数据缓冲大小，默认设置1024。–影响性能
    # wsize 写入数据缓冲大小，默认设置1024。
    # fg 以前台形式执行挂载操作，默认设置。在挂载失败时会影响正常操作响应。
    # bg 以后台形式执行挂载操作。
    # hard 硬式挂载，默认设置。如果与服务器通讯失败，让试图访问它的操作被阻塞，直到服务器恢复为止。
    # soft 软式挂载。服务器通讯失败，让试图访问它的操作失败，返回一条出错消息。这项功能对于避免进程挂在无关紧要的安装操作上来说非常有用。
    # retrans=n 指定在以软方式安装的文件系统上，在返回一条出错消息之前重复发出请求的次数。
    # nointr 不允许用户中断，默认设置。
    # intr 允许用户中断被阻塞的操作并且让它们返回一条出错消息。
    # timeo=n 设置请求的超时时间以十分之一秒为单位。
    # tcp 传输默认使用udp,可能出现不稳定，使用proto=tcp更改传输协议。客户端参考mountproto=netid
    # （以上内容：参考：man nfs）
    ```

  - 重启服务
    ```bash
    systemctl restart nfs
    ```
  - 检查本地共享目录
    ```bash
    showmount -e localhost
    Export list for localhost:
    /data 192.168.0.0/24
    ```
  - 修改服务端目录权限
    由于 NFS 同步文件时只能同步文件的用户 uid 而无法同步用户名，所以所有用户 UID 需要保持一致，否则会因为权限问题而无法访问。
    ```bash
    # 创建 nginx 用户且不能登录。false==nologin
    useradd -m -U -d /home/nginx -s /bin/false nginx

    # 修改用户 UID
    usermod -u 666 nginx

    # 修改用户 GID
    groupmod -g 6666 nginx

    # 拒绝系统用户登录，可以将其shell设置为/usr/sbin/nologin或者/bin/false
    usermod -s | --shell /usr/sbin/nologin nginx

    # or  {nologin会礼貌的向用户显示一条信息，并拒绝用户登录，信息在/etc/}
    usermod -s | -shell /bin/false nginx

    # 锁定用户账户
    passwd -l | --lock username

    # 解锁用户账户
    passwd -u | --unlock username

    # 删除用户密码
    passwd -d | --delete username

    # /etc/nologin：
    # 如果存在/etc/nologin文件，则系统只允许root用户登录，其他用户全部被拒绝登录，并向他们显示/etc/nologin文件的内容。
    ```
    >这样，服务端就配置好了，接下来配置客户端，连接服务端，使用共享目录。

    [详细的用户操作命令](https://www.cnblogs.com/EasonJim/p/7158491.html)

##客户端

###客户端安装
  - 与服务端类似
    ```bash
    yum install nfs-utils
    ```
###客户端配置
  - 设置 rpcbind 服务的开机自启并启动
    ```bash
    systemctl enable --now rpcbind
    ```
    >注意：客户端不需要打开防火墙，因为客户端时发出请求方，网络能连接到服务端即可。 客户端也不需要开启 NFS 服务，因为不共享目录。

###客户端连接 NFS
  - 先查服务端的共享目录
    ```bash
    [root@nginx-node-1 mnt]# showmount -e 192.168.0.199
    Export list for 192.168.0.199:
    /mnt 192.168.0.0/24
    ```
  - 在客户端挂载 NFS
    ```bash
    mount -t nfs -o sync 192.168.0.199:/src /dest

    # 注意：如果没有 -o sync 选项，则会造成在 nfs 服务端修改文件，客户端无法及时同步的问题。
    # -o 选项：[default:async]/sync 异步写入/同步写入磁盘。
    # defauts 默认值：rw,suid,dev,exec,auto,async,nouser。

    # 写入 fstab 文件实现开机挂载
    # vim /etc/fstab
    # 192.168.0.199:/mnt/www/html /var/www/html        nfs     rw,suid,dev,exec,auto,sync,nouser        0 0
    ```

    挂载之后，可以使用 mount 命令查看一下
    ```bash
    [root@nginx-node-1 mnt]# mount
    ...
    ...
    ...
    192.168.0.199:/mnt on /mnt type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,clientaddr=192.168.0.95,local_lock=none,addr=192.168.0.199)
    [root@nginx-node-1 mnt]#
    ```
    >这说明已经挂载成功了。

###测试 NFS
  - 在客户端向共享目录创建一个文件
    ```bash
    [root@nginx-node-1 mnt]# touch www/nfs.test
    ```

    之后取 NFS 服务端 192.168.0.199 查看一下
    ```bash
    [root@nfs-node-1 mnt]# ll www/
    total 0
    drwxr-xr-x 2 nginx nginx 6 Aug 18 16:13 html
    -rw-r--r-- 1 root  root  0 Aug 18 18:04 nfs.test
    [root@nfs-node-1 mnt]#
    ```
    可以看到，共享目录已经写入了。

###客户端自动挂载
  - 自动挂载很常用，客户端设置一下即可。
    ```bash
    vim /etc/fstab
    ```
  - 在结尾添加类似如下配置
    ```conf
    #
    # /etc/fstab
    # Created by anaconda on Fri Aug 16 10:09:51 2019
    # Accessible filesystems, by reference, are maintained under '/dev/disk'
    # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
    #
    /dev/mapper/centos-root /                        xfs     defaults        0 0
    UUID=164e49a9-51a3-4a39-871e-86c5fc5bab32 /boot  xfs     defaults        0 0
    /dev/mapper/centos-swap swap                     swap    defaults        0 0
    192.168.0.199:/mnt /mnt                          nfs     defaults        0 0

    ```
  - 重新加载 systemctl
    由于修改了 /etc/fstab，需要重新加载 systemctl。
    ```bash
    systemctl daemon-reload
    ```
  - 查看挂载点
    ```bash
    [root@nginx-node-1 mnt]# mount
    ...
    ...
    ...
    192.168.0.199:/mnt on /mnt type nfs4 (rw,relatime,vers=4.1,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,clientaddr=192.168.0.95,local_lock=none,addr=192.168.0.199)
    [root@nginx-node-1 mnt]#
    ```
  >此时已经启动好了。如果实在不放心，可以重启一下客户端的操作系统，之后再查看一下。

##相关链接
  [Chapter 8. Network File System (NFS) - Red Hat Customer Portal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/ch-nfs)
  [Setting Up NFS Server And Client On CentOS 7](https://www.unixmen.com/setting-nfs-server-client-centos-7/)
  [CentOS 7 下 yum 安装和配置 NFS](https://qizhanming.com/blog/2018/08/08/how-to-install-nfs-on-centos-7)
  [NFS刷新（同步）](https://blog.csdn.net/sahusoft/article/details/8629928)

