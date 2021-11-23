### 网络命令

#### nestat

```bash
netstat
```

```
usage: netstat [-vWeenNcCF] [<Af>] -r         netstat {-V|--version|-h|--help}
       netstat [-vWnNcaeol] [<Socket> ...]
       netstat { [-vWeenNac] -I[<Iface>] | [-veenNac] -i | [-cnNe] -M | -s [-6tuw] } [delay]

        -r, --route              display routing table
        -I, --interfaces=<Iface> display interface table for <Iface>
        -i, --interfaces         display interface table
        -g, --groups             display multicast group memberships
        -s, --statistics         display networking statistics (like SNMP)
        -M, --masquerade         display masqueraded connections

        -v, --verbose            be verbose
        -W, --wide               don't truncate IP addresses
        -n, --numeric            don't resolve names
        --numeric-hosts          don't resolve host names
        --numeric-ports          don't resolve port names
        --numeric-users          don't resolve user names
        -N, --symbolic           resolve hardware names
        -e, --extend             display other/more information
        -p, --programs           display PID/Program name for sockets
        -o, --timers             display timers
        -c, --continuous         continuous listing

        -l, --listening          display listening server sockets
        -a, --all                display all sockets (default: connected)
        -F, --fib                display Forwarding Information Base (default)
        -C, --cache              display routing cache instead of FIB
        -Z, --context            display SELinux security context for sockets
```

##### ip 和 tcp 分析

查看连接某服务端口最多的 ip 地址：

```
netstat -ntu | grep :22 | awk '{print $5}' | cut -d: -f1 | awk '{++ip[$1]} END {for (i in ip) print ip[i],"\t",i}' | sort -nr
```

tcp 各种状态数量列表：

```
netstat -nt | grep -e 127.0.0.1 -e 0.0.0.0 -e ::: -v | awk '/^tcp/ {++state[$NF]} {for (i in state) print i,"\t",state[i]}'
```

查看某进程数，如果接近预设值，说明不够用，需要增加：

```
netstat -anpo | grep "php-cgi" | wc -l
```

##### 常用示例

列出所有端口

```
netstat -a  # 列出所有端口
netstat -at # 列出所有 tcp 端口
netstat -au # 列出所有 udp 端口
```

列出所有处于监听状态的 sockets

```
netstat -l  # 只显示监听端口
netstat -lt # 只列出所有监听 tcp 端口
netstat -lu # 只列出所有监听 dup 端口
netstat -lx # 只列出所有监听 unix 端口
```

显示每个协议的统计信息

```
netstat -s   # 显示所有端口的统计信息
netstat -st  # 显示所有 tcp 端口的统计信息
netstat -su  # 显示所有 udp 端口的统计信息
```

```
# 在 netstat 输出中显示 pid 和进程名称
netstat -pt

# netstat -p 可以与其他开关一起使用，就可以添加 "pid/进程名称" 到 netstat 输出中，这样 debugging 时候可以很方便的发现特定端口运行的程序。
```

**在 netstat 输出中不显示主机，端口和用户名（host，port or user）**

当不想让主机，端口和用户名显示，使用 netstat -n ，将会使用数字代替哪些名称，同样可以加速输出，因为不用进行对比查询。

```
netstat -an
```

如果只是不想让这三个名称中的一个被显示，使用以下命令：

```
-n, --numeric            don't resolve names
--numeric-hosts          don't resolve host names
--numeric-ports          don't resolve port names
--numeric-users          don't resolve user names
```

持续输出 netstat 信息

```
netstat -c # 每隔一秒输出网络信息
```

显示系统不支持的地址族 (Address Families)

```
netstat --verbose
```

显示核心路由信息

```
netstat -r
```

找出程序运行的端口

```
# 并不是所有的进程都能找到，没有权限的会不显示，使用 root 权限查看所有的信息。
netstat -ap | grep ssh
```

找出运行在指定端口的进程：

```
netstat -an | grep ':80'
```

通过端口找进程 id

```
netstat -anp | grep 8081 | grep LISTEN | awk '{printf $7}' | cut -d/ -f1
```

显示网络接口列表

```
netstat -i
[root@centos8 ~]# netstat -i
Kernel Interface table
Iface             MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
eth0             1500    29963      0      0 0         11483      0      0      0 BMRU
lo              65536     7998      0      0 0          7998      0      0      0 LRU
```

显示网络接口列表扩展信息 （IP 地址信息）

```
netstat -ie
[root@centos8 ~]# netstat -ie
Kernel Interface table
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.17.0.124  netmask 255.255.255.0  broadcast 172.17.0.255
        inet6 fe80::216:3eff:fe06:3a1  prefixlen 64  scopeid 0x20<link>
        ether 00:16:3e:06:03:a1  txqueuelen 1000  (Ethernet)
        RX packets 29948  bytes 32925734 (31.4 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 11474  bytes 1811104 (1.7 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 7998  bytes 671832 (656.0 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 7998  bytes 671832 (656.0 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

