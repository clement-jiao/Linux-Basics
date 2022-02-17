# 部署 keepalived + haproxy

日期：2022-01-08

### 安装软件包

```bash
root@ubuntu:~$ root@debian:~$ apt install -y net-tools keepalived haproxy
```

## 配置 keepalived master 10

```bash
root@ubuntu:~$ cp /usr/share/doc/keepalived/samples/keepalived.conf.vrrp /etc/keepalived/keepalived.conf

root@ubuntu:~$ cat /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state MASTER
    interface ens33
    garp_master_delay 10
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        # optional label. should be of the form "realdev:sometext" for
        # compatibility with ifconfig.
        # 注意不能绑定本机ip。网卡为 eth0 的要全局替换掉。
        # backup 要开启内核参数 net.ipv4.ip_nonlocal_bind=1，用以开启对非本机 ip 地址的监听，默认是0。
        192.168.11.111 label ens33:0
        192.168.11.112 label ens33:1
        192.168.11.113 label ens33:2
    }
}

```

### 启动服务 master 10

```bash
root@ubuntu133:~$ systemctl --now enable keepalived
s
root@ubuntu133:~$ ifconfig 
...
ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.11.10  netmask 255.255.255.0  broadcast 192.168.11.255
        inet6 fe80::20c:29ff:fefc:1cfd  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:fc:1c:fd  txqueuelen 1000  (Ethernet)
        RX packets 22357545  bytes 1341569577 (1.2 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 22432070  bytes 1659050766 (1.5 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens33:0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.11.111  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:fc:1c:fd  txqueuelen 1000  (Ethernet)

ens33:1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.11.112  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:fc:1c:fd  txqueuelen 1000  (Ethernet)

ens33:2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.11.113  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:fc:1c:fd  txqueuelen 1000  (Ethernet)
...

```

### 配置从机 backup 13

```bash
root@ubuntu134:~$ cat /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    garp_master_delay 10
    virtual_router_id 51
    priority 80
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        # optional label. should be of the form "realdev:sometext" for
        # compatibility with ifconfig.
        # 注意不能绑定本机ip。网卡为 eth0 的要全局替换掉。
        # 与 master 配置一样
        # backup 要开启内核参数 net.ipv4.ip_nonlocal_bind=1，用以开启对非本机 ip 地址的监听，默认是0。
        192.168.11.111 label ens33:0
        192.168.11.112 label ens33:1
        192.168.11.113 label ens33:2
    }
}


systemctl enable keepalived
systemctl start keepalived

systemctl status keepalived

```

### 停 master 10 上的 keepalived

```bash
root@ubuntu133:~$ systemctl stop keepalived.service 
root@ubuntu133:~$ ip a
...
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:fc:1c:fd brd ff:ff:ff:ff:ff:ff
    altname enp2s1
    inet 192.168.11.10/24 brd 192.168.11.255 scope global dynamic ens33
       valid_lft 1509sec preferred_lft 1509sec
    inet6 fe80::20c:29ff:fefc:1cfd/64 scope link 
       valid_lft forever preferred_lft forever
...

```

### 查看 backup 13 上的网卡

```
root@ubuntu13:~$ ifconfig 
ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.11.13  netmask 255.255.255.0  broadcast 192.168.11.255
        inet6 fe80::20c:29ff:fee1:7406  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:e1:74:06  txqueuelen 1000  (Ethernet)
        RX packets 22598719  bytes 1356205511 (1.2 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 22518038  bytes 1666341281 (1.5 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens33:0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.11.111  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:e1:74:06  txqueuelen 1000  (Ethernet)

ens33:2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.11.112  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:e1:74:06  txqueuelen 1000  (Ethernet)

ens33:3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.11.113  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:e1:74:06  txqueuelen 1000  (Ethernet)

```

### 查看 ip 切换之后的 arp

```bash
➜  ~ arp -a
? (192.168.11.11) at 00:0c:29:33:a1:2b [ether] on ens33
? (192.168.11.100) at 00:50:56:ea:45:86 [ether] on ens33
? (192.168.11.1) at 00:50:56:c0:00:08 [ether] on ens33
? (192.168.11.2) at 00:50:56:f0:a1:88 [ether] on ens33

```

### 配置 haproxy

```bash
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg_bak

cat >> /etc/haproxy/haproxy.cfg <<"EOF"

listen k8s-6443
 bind 192.168.11.111:6443
 mode tcp    # 注意 tcp 模式
 server 192.168.11.11 192.168.11.11:6443 check  inter 2 fall 3 rise 3
EOF

# 添加内核参数
net.ipv4.ip_nonlocal_bind = 1



systemctl restart haproxy

systemctl --now enable haproxy

systemctl status haproxy

```

### 查看端口监听

```
root@ubuntu133:~$ netstat -nlpt
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 192.168.11.111:6443     0.0.0.0:*               LISTEN      930/haproxy         
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      434/sshd: /usr/sbin 
tcp        0      0 127.0.0.1:6010          0.0.0.0:*               LISTEN      3246/sshd: root@pts 
tcp6       0      0 :::22                   :::*                    LISTEN      434/sshd: /usr/sbin 
tcp6       0      0 ::1:6010                :::*                    LISTEN      3246/sshd: root@pts


root@ubuntu134:~$ netstat -nlpt
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 192.168.11.111:6443     0.0.0.0:*               LISTEN      930/haproxy         
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      434/sshd: /usr/sbin 
tcp        0      0 127.0.0.1:6010          0.0.0.0:*               LISTEN      3246/sshd: root@pts 
tcp6       0      0 :::22                   :::*                    LISTEN      434/sshd: /usr/sbin 
tcp6       0      0 ::1:6010                :::*                    LISTEN      3246/sshd: root@pts
```

