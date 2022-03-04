# redis教程

[TOC]



## 基础环境

centos7

## redis源码安装

```shell
yum -y install gcc libc

make MALLOC=libc

make install 
```

## 基础编译环境

```shell
yum -y install gcc libc
```

## redis二进制安装

```shell
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make 
make installm
```

修改redis配置文件

```shell
#默认只能本机访问，改为允许所有访问
bind 0.0.0.0
#修改默认端口号(非必要，生产环境为了安全性建议修改默认端口)
port 16379
#后台运行
daemonize yes
#修改密码认证
requirepass password
```

启动redis

```shell
redis-server /etc/redis.conf
```

## redis加入系统服务并设置成为开机自启动

1.新建对应redis的配置目录

```shell
sudo mkdir /etc/redis
sudo mkdir /var/redis
```

2.拷贝配置文件并重命名

```shell
cp redis.conf /etc/redis/6379.conf
```

3.在 /var/redis 中创建一个目录，作为此 Redis 实例的数据和工作目录

```shell
mkdir /var/redis/6379
```

4.编辑配置文件

```shell
将pidfile设置为`/var/run/redis_6379.pid`（如果需要，修改端口）
pidfile /var/run/redis_6379.pid
相应地更改端口。在我们的示例中不需要它，因为默认端口已经是 6379。
port 6379
设置您的首选日志级别
loglevel notice
将日志文件设置为`/var/log/redis_6379.log`
logfile "/var/log/redis_6379.log"
将目录设置为 /var/redis/6379（非常重要的一步！）
dir /var/redis/6379
```

5.添加系统服务

```shell
vim /usr/lib/systemd/system/redis.service

[Unit]
Description=Redis
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/redis/redis.pid
ExecStart=/usr/local/bin/redis-server /usr/local/redis/redis.conf
ExecReload=/bin/kill -s HUP $MAINPID 
ExecStop=/bin/kill -s QUIT $MAINPID 
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

6.重载系统服务

```shell
systemctl daemon-reload
```

7.启动redis

```shell
systemctl start redis
```

## redis-cli客户端常用命令

停止redis服务

```shell
redis-cli 

127.0.0.1:6379> shutdown
```

或者强制停止

```shell
kill -9 redis的进程
```

测试连接ping,显示pong

```shell
redis-cli 
127.0.0.1:6379> ping 
pong
```

## redis集群

### redis主从

在从节点修改如下配置，重启redis

```shell
replicaof "masterip" 6379
#设置从库为只读，这个是默认的
replica-read-only yes
masterauth  "password"
```

通过redis-cli客户端命令在主节点通过info查看主从状态,在replication下能看到如下对应加入的从节点信息

127.0.0.1:6379> info

```shell
# Replication
role:master
connected_slaves:2
slave0:ip=192.168.211.140,port=6379,state=online,offset=434,lag=0
slave1:ip=192.168.211.139,port=6379,state=online,offset=434,lag=1
master_failover_state:no-failover
master_replid:4127590d94a36a4423e2f1297b833f94d7263114
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:434
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:434

```

### redis哨兵

哨兵模式工作示意图如下

![img](https://images2018.cnblogs.com/blog/907596/201805/907596-20180507190932477-2053887895.png)

server1掉线后

![img](https://images2018.cnblogs.com/blog/907596/201805/907596-20180507190947053-1114526030.png)

server2成为新的master服务器

![img](https://images2018.cnblogs.com/blog/907596/201805/907596-20180507191002090-81723534.png)

主从三个节点配置如下

```shell
port 26379
pidfile ``"/usr/local/redis/var/redis-sentinel.pid"
dir` `"/usr/local/redis/data/sentinel"
daemonize ``yes
protected-mode no
logfile ``"/usr/local/redis/var/redis-sentinel.log"
sentinel monitor myMaster 主节点ip 6379 2 
sentinel down-after-milliseconds myMaster 10000 
sentinel parallel-syncs myMaster 1
sentinel failover-timeout myMaster 60000 
```

将redis-sentinel注册为system服务，将如下路径改为实际路径

```shell
cat > /usr/lib/systemd/system/redis-sentinel.service <<EOF
[Unit]
Description=Redis persistent key-value database
After=network.target
After=network-online.target
Wants=network-online.target
[Service]
ExecStart=/data/redis/bin/redis-sentinel /data/redis/conf/sentinel.conf --supervised systemd
ExecReload=/bin/kill -s HUP $MAINPID 
ExecStop=/bin/kill -s QUIT $MAINPID
Type=notify
User=root
Group=root
RuntimeDirectory=root
RuntimeDirectoryMode=0755
[Install]
WantedBy=multi-user.target
EOF
```

在所有服务器上执行如下命令，服务重载并重启redis-sentinel服务

```shell
systemctl daemon-reload

systemctl restart redis-sentinel
```

在master节点验证主从状态

```shell
查看Master节点信息：
[root@redis-master src]``# redis-cli -h 192.168.10.202 -p 6379 info Replication
# Replication
role:master
connected_slaves:2
slave0:ip=192.168.10.203,port=6379,state=online,offset=61480,lag=0
slave1:ip=192.168.10.205,port=6379,state=online,offset=61480,lag=0
master_replid:96a1fd63d0ad9e7903851a82382e32d690667bcc
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:61626
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:61626
```

测试验证哨兵是否正常，sentinels显示3表示正常

```
[root@redis-master ~]``# redis-cli -h 192.168.10.205 -p 26379 info Sentinel
# Sentinel
sentinel_masters:1
sentinel_tilt:0
sentinel_running_scripts:0
sentinel_scripts_queue_length:0
sentinel_simulate_failure_flags:0
master0:name=redisMaster,status=ok,address=192.168.10.202:6379,slaves=2,sentinels=3
```

最后可以模拟故障切换，将master停止服务，看slave是否会自动升级成为master

1.在主节点执行停止命令

systemctl stop redis

2.查看sentinel日志，发现有检测到主节点连接失败，通知下线

3.查看其中一个slave的状态，发现已经升级为master



参考文档：https://www.cnblogs.com/kevingrace/p/9004460.html

