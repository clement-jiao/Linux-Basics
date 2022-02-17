# Debian11 安装 NFS

Configure NFS Server to share directories on your Network.

This example is based on the environment like follows.

```
+----------------------+       |       +----------------------+
| [    NFS Server    ] |10.0.0.30 | 10.0.0.51| [    NFS Client    ] |
|     dlp.srv.world    +----------+----------+   node01.srv.world   |
|           |          |           |
+----------------------+          +----------------------+
```

## 配置服务

```bash
root@dlp:~$ apt -y install nfs-kernel-server nfs-common

#不太清楚为啥要配置域名，可能与 【nfs只能挂载为nobody的解决方法】 有关
root@dlp:~$ vi /etc/idmapd.conf
# line 6 : uncomment and change to your domain name
Domain = srv.world

root@dlp:~$ vi /etc/exports
# write settings for NFS exports
# for example, set [/home/nfsshare] as NFS share
/home/nfsshare 10.0.0.0/24(rw,no_root_squash)

root@dlp:~$ mkdir /home/nfsshare
root@dlp:~$ systemctl restart nfs-server
root@dlp:~$ netstat -pantu | grep 2049
tcp        0      0 0.0.0.0:2049         0.0.0.0:*        LISTEN      -        
tcp6       0      0 :::2049      :::*         LISTEN      -        
udp        0      0 0.0.0.0:2049         0.0.0.0:*         -        
udp6       0      0 :::2049      :::*      -        

root@dlp:~$ showmount -e
Export list for dlp:
/home/nfsshare 10.0.0.0/24
```

### 其余选项

其余可参考：[centos7-nfs](../CentOS7/centos7-nfs.md)，或者参考资料中的 NFS 配置说明，写得还是比较详细的

## 注意

与 centos7 不同的是 Debian 的 nfs 貌似并不会在 systemctl 中看到已启动的 nfs-server 服务，在查看状态时是 Finished

```bash
# 启动后就退出了，也许是有个 rpcbind 之类的服务在监听 socket ？
root@K8S-nfs:~$ systemctl status nfs-server.service 
● nfs-server.service - NFS server and services
     Loaded: loaded (/lib/systemd/system/nfs-server.service; enabled; vendor preset: enabled)
     Active: active (exited) since Thu 2022-02-17 08:06:51 CST; 21h ago
    Process: 927 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
    Process: 928 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
   Main PID: 928 (code=exited, status=0/SUCCESS)
        CPU: 5ms

Feb 17 08:06:50 debian systemd[1]: Starting NFS server and services...
Feb 17 08:06:50 debian exportfs[927]: exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "*:/k8s/data".
Feb 17 08:06:50 debian exportfs[927]:   Assuming default behaviour ('no_subtree_check').
Feb 17 08:06:50 debian exportfs[927]:   NOTE: this default has changed since nfs-utils version 1.0.x
Feb 17 08:06:51 debian systemd[1]: Finished NFS server and services.
```

### rpcbind

```bash
root@debian:~$ systemctl status rpcbind.service 
● rpcbind.service - RPC bind portmap service
     Loaded: loaded (/lib/systemd/system/rpcbind.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2022-02-17 08:03:18 CST; 21h ago
TriggeredBy: ● rpcbind.socket
       Docs: man:rpcbind(8)
   Main PID: 338 (rpcbind)
      Tasks: 1 (limit: 1093)
     Memory: 1.3M
        CPU: 128ms
     CGroup: /system.slice/rpcbind.service
          └─338 /sbin/rpcbind -f -w

Feb 17 08:03:18 debian systemd[1]: Starting RPC bind portmap service...
Feb 17 08:03:18 debian systemd[1]: Started RPC bind portmap service.
```

### ss

```bash
root@debian:~$ ss -tunlp | grep rpc
```

### 分配的内存

分配内存要 1G 左右，实测 512M 会启动失败，提示无法分配内存（甚至还开过 swap）。不太清楚为啥一个 NFS 要这么内存。

## fuser

在参考资料【nfs只能挂载为nobody的解决方法】中有一个重要工具 `fuser`，

工具描述为：`Show which processes use the named files, sockets, or filesystems.`

然而在Debian11中并没有这个工具，所以：

```bash
root@debian:~$ fuser --help
-bash: fuser: command not found
root@debian:~$ apt search fuser
Sorting... Done
Full Text Search... Done
cloudsql-proxy/stable 1.17.0-5+b6 amd64
  # connect securely to a 2nd generation Cloud SQL DB

hxtools/stable 20201116-1 amd64
  # Collection of tools and scripts

psmisc/stable 23.4-2 amd64
  # utilities that use the proc file system

python3-odf/stable 1.4.1-1 all
  # Python3 API to manipulate OpenDocument files

sra-toolkit/stable 2.10.9+dfsg-2 amd64
  # utilities for the NCBI Sequence Read Archive

# 看他们的描述貌似只有 psmisc 最像了。
root@debian:~$ apt install psmisc 
...

root@debian:~$ fuser --help
fuser: Invalid option --help
Usage: fuser [-fIMuvw] [-a|-s] [-4|-6] [-c|-m|-n SPACE]
          [-k [-i] [-SIGNAL]] NAME...
       fuser -l
       fuser -V
Show which processes use the named files, sockets, or filesystems.

  -a,--all           display unused files too
  -i,--interactive      ask before killing (ignored without -k)
  -I,--inode         use always inodes to compare files
  -k,--kill          kill processes accessing the named file
  -l,--list-signals     list available signal names
  -m,--mount         show all processes using the named filesystems or

```



## 参考资料：

[Server World - ネットワークサーバー構築 (server-world.info)](https://www.server-world.info/)

[Debian 11 Bullseye : Configure NFS Server : Server World (server-world.info)](https://www.server-world.info/en/note?os=Debian_11&p=nfs&f=1)

[nfs只能挂载为nobody的解决方法 – 云原生之路 (361way.com)](https://www.361way.com/nfs-mount-nobody/2616.html)

[Debian9.5 系统配置NFS配置说明 - pipci - 博客园 (cnblogs.com)](https://www.cnblogs.com/pipci/p/9935572.html)