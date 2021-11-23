### ss (sockets statitics)

比 netstat 好用的 socket 统计信息， iproute2 包附带的另一个工具，允许你查询 socket 的有关统计信息

#### 补充说明

ss命令 用来显示处于活动状态的套接字信息。ss命令可以用来获取 socket 统计信息，它可以显示和 netstat 类似的内容。但 ss 的优势在于能够显示更多更详细的有关 tcp 和连接状态的信息，而且比 netstat 更快速更高效。

当服务器的 socket 连接数量变得非常大时，无论是使用 netstat 命令还是直接 cat /proc/net/tcp ，执行速度都会很慢，尤其当连接数大于 1w 。ss 快是因为利用到 tcp 协议栈中 tcp_diag。tcp_diag是一个用于分析统计的模块，可以获得 Linux 内核中第一手的信息，这就确保了 ss 的快捷高效。当然如果你的系统中没有 tcp_diag ，ss 也可以运行，只是效率稍慢。

#### 语法

```
ss [参数]
ss [参数] [过滤]
```

#### 选项

```
Usage: ss [ OPTIONS ]
       ss [ OPTIONS ] [ FILTER ]
   -h, --help          this message
   -V, --version       output version information
   -n, --numeric       don't resolve service names				# 不解析服务名
   -r, --resolve       resolve host names									# 解析主机名
   -a, --all           display all sockets
   -l, --listening     display listening sockets					# 显示监听状态的套接字
   -o, --options       show timer information							# 显示计时器的信息
   -e, --extended      show detailed socket information	  # 显示扩展信息
   -m, --memory        show socket memory usage						# 显示套接字的内存使用情况
   -p, --processes     show process using socket					# 显示使用套接字的进程
   -i, --info          show internal TCP information			# 显示 tcp 内部信息
       --tipcinfo      show internal tipc socket information
   -s, --summary       show socket usage summary					# 显示套接字使用概况
       --tos           show tos and priority information
       --cgroup        show cgroup information
   -b, --bpf           show bpf filter socket information
   -E, --events        continually display sockets as they are destroyed
   -Z, --context       display process SELinux security contexts
   -z, --contexts      display process and socket SELinux security contexts
   -N, --net           switch to the specified network namespace name

   -4, --ipv4          display only IP version 4 sockets
   -6, --ipv6          display only IP version 6 sockets
   -0, --packet        display PACKET sockets							# 显示 packte 套接字
   -t, --tcp           display only TCP sockets
   -M, --mptcp         display only MPTCP sockets
   -S, --sctp          display only SCTP sockets
   -u, --udp           display only UDP sockets
   -d, --dccp          display only DCCP sockets
   -w, --raw           display only RAW sockets
   -x, --unix          display only Unix domain sockets
       --tipc          display only TIPC sockets
       --vsock         display only vsock sockets
   -f, --family=FAMILY display sockets of type FAMILY			# 显示 family 类型套接字
   FAMILY := {inet|inet6|link|unix|netlink|vsock|tipc|xdp|help} # 可选 unix，inet，link等
   -K, --kill          forcibly close sockets, display what was closed
   -H, --no-header     Suppress header line
   -O, --oneline       socket's data printed on a single line

   -A, --query=QUERY, --socket=QUERY
       QUERY := {all|inet|tcp|mptcp|udp|raw|unix|unix_dgram|unix_stream|unix_seqpacket|packet|netlink|vsock_stream|vsock_dgram|tipc}[,QUERY]

   -D, --diag=FILE     Dump raw information about TCP sockets to FILE
   -F, --filter=FILE   read filter information from FILE
       FILTER := [ state STATE-FILTER ] [ EXPRESSION ]
       STATE-FILTER := {all|connected|synchronized|bucket|big|TCP-STATES}
         TCP-STATES := {established|syn-sent|syn-recv|fin-wait-{1,2}|time-wait|closed|close-wait|last-ack|listening|closing}
          connected := {established|syn-sent|syn-recv|fin-wait-{1,2}|time-wait|close-wait|last-ack|closing}
       synchronized := {established|syn-recv|fin-wait-{1,2}|time-wait|close-wait|last-ack|closing}
             bucket := {syn-recv|time-wait}
                big := {established|syn-sent|fin-wait-{1,2}|closed|close-wait|last-ack|listening|closing}
```

#### 示例

```
ss -t -a 		# 显示 tcp 连接
ss -s 	 		# 显示 sockets 摘要
ss -l		 		# 列出所有打开的网络连接端口
ss -lp	 		# 查看进程使用的socket
ss -u -a		# 显示所有 udp sockets
ss -lp | grep 3306 # 找出打开套接字/端口的应用程序

# 显示所有状态为 established 的 SMTP 连接
ss -o state established '( dport = :smtp or sport = :smtp )'

# 显示所有状态为 established 的 http 连接
ss -o state established '( dport = :http or sport = :http )'

# 列举出处于 fin-wait-1 状态的源端口为 80 或 443，目标网络为 192.168.9/24 所有 tcp 套接字
ss -o state fin-wait-1 '( sport = :http or sport= :https )' dst 192.168.9/24
```

##### 效率对比

```
time netstae -at
time ss
```

##### 匹配远程地址和端口号

```
# ss dst address_pattern
ss dst 192.168.1.5
ss dst 192.168.1.5:http
ss dst 192.168.1.5:smtp
ss dst 192.168.1.5:3306
```

##### 将本地或远程端口和一个数比较

```
# ss dport op port 远程/(目标dest) 端口和一个数比较
# ss sport op port 本地/(源src)   端口和一个数比较
# op 可以代表以下任意一个：
# <= or le ：小于或等于端口号
# >= or ge ：大于或冬雨端口号
# != or ne ：不等于端口号
# < or gt  ：小于端口号
# > or lt  ：大于端口号

ss sport = :http
ss dport = :http
ss dport \> :1024
ss sport \> :1024
ss sport \< :32000
ss sport eq :22
ss dport eq :22
ss dport != :22
ss state connected sport = :http
ss \( dport = :http or sport = :https \)
ss -o state fin-wait-1 \( sport = :http or sport = :https \) dst 192.168.1/24
```

用 tcp 状态过滤 sockets

```
ss -4 state closeing
# ss -4 state FILTER-NAME-HERE
# ss -6 state FILTER-NAME-HERE
# FILTER-NAME-HERE 可以代表以下任何一个：
# established、syn-sent、syn-recv、fin-wait-1、fin-wait-2、time-wait、closed、close-wait、last-ack、listen、closing
# all：所有以上状态
# connected：除了 listen and closing 的所有状态
# synchronized：所有已连接的状态除了 syn-sent
# bucket：显示状态为 maintained as minisockets，例如：time-wait 和syn-recv
# big：和 bucket 相反。
```

显示 tcp 连接

```
[root@centos8 ~]# ss -t -a
State                Recv-Q   Send-Q    Local Address:Port     Peer Address:Port      Process
LISTEN               0        128       0.0.0.0:ssh            0.0.0.0:*
TIME-WAIT            0        0         172.17.0.124:45774     100.100.30.60:https
ESTAB                0        36        172.17.0.124:ssh       124.79.53.220:55924
ESTAB                0        0         172.17.0.124:47320     100.103.2.231:http
```

显示 sockets 摘要

```
[root@centos8 ~]# ss -s
Total: 165
TCP:   4 (estab 2, closed 1, orphaned 0, timewait 1)
Transport Total     IP        IPv6
RAW	      0         0         0
UDP	      3         2         1
TCP   	  3         3         0
INET  	  6         5         1
FRAG  	  0         0         0

# 列出当前的 established、closed、orphaned、and waiting tcp sockets
```

列出所有打开的网络连接端口

```
[root@centos8 ~]# ss -l
Netid    State    Recv-Q  Send-Q  Local Address:Port            Peer Address:Port  Process
nl       UNCONN   0       0       rtnl:855638714                *
nl       UNCONN   0       0       rtnl:NetworkManager/867       *
nl       UNCONN   0       0       rtnl:kernel                   *
nl       UNCONN   0       0       rtnl:NetworkManager/867       *
nl       UNCONN   0       0       rtnl:855638714                *
p_dgr    UNCONN   0       0       ip:eth0                       *
u_str    LISTEN   0       5       /var/run/lsm/ipc/simc 20491   * 0
u_str    LISTEN   0       5       /var/run/lsm/ipc/sim 20493    * 0
u_dgr    UNCONN   0       0       /run/systemd/notify 11573     * 0
u_dgr    UNCONN   0       0       /run/systemd/cgroups-agent 11575  * 0
```

查看进程使用的 socket

```
[root@centos8 ~]# ss -pl
```

找出打开套接字/端口的应用程序

```
[root@centos8 ~]# ss -lp | grep 22
```

显示所有 udp sockets

```
[root@centos8 ~]# ss -u -a
```

所有出端口为 22 (ssh) 的连接

```
[root@centos8 ~]# ss state all sport = :ssh
```







