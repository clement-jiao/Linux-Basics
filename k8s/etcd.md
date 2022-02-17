# k8s组件——etcd

## 介绍



```bash
root@k8s-etcd-1:/etc/systemd/system$ cat /etc/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd	# 数据保存目录
ExecStart=/usr/bin/etcd \		# 二进制目录
  --name=etcd-192.168.11.16 \	# 当前 node/节点 名称
  --cert-file=/etc/kubernetes/ssl/etcd.pem \
  --key-file=/etc/kubernetes/ssl/etcd-key.pem \
  --peer-cert-file=/etc/kubernetes/ssl/etcd.pem \
  --peer-key-file=/etc/kubernetes/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
  --peer-trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
  --initial-advertise-peer-urls=https://192.168.11.16:2380 \	# 通告自己的集群端口（首次连接）
  --listen-peer-urls=https://192.168.11.16:2380 \				# 集群间通信端口
  --listen-client-urls=https://192.168.11.16:2379,http://127.0.0.1:2379 \	# 客户端访问地址（首次连接）
  --advertise-client-urls=https://192.168.11.16:2379 \			# 客户端通信端口
  --initial-cluster-token=etcd-cluster-0 \						# 创建集群使用的 token，一个集群内的节点保持一致
  --initial-cluster=etcd-192.168.11.16=https://192.168.11.16:2380,etcd-192.168.11.17=https://192.168.11.17:2380,etcd-192.168.11.18=https://192.168.11.18:2380 \  # 集群所有节点信息
  --initial-cluster-state=new \				# 新建集群时值为 new，如果是已存在集群为 existing。（标识本机是主或从节点）
  --data-dir=/var/lib/etcd \				# 数据目录路径
  --wal-dir= \
  --snapshot-count=50000 \					# 快照
  --auto-compaction-retention=1 \			# 保存时压缩数据
  --auto-compaction-mode=periodic \			# 压缩模式：完整压缩
  --max-request-bytes=10485760 \			# 最大请求数据（10MB）
  --quota-backend-bytes=8589934592			# 最大后端请求数据的配额（8GB）
Restart=always
RestartSec=15
LimitNOFILE=65536
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
```

## 命令参数整理

```bash
root@k8s-etcd-1:~$ etcdctl --help
NAME:
	etcdctl - A simple command line client for etcd3.
USAGE:
	etcdctl [flags]
VERSION:
	3.5.0
API VERSION:
	3.5

COMMANDS:
	alarm disarm			Disarms all alarms				# 解除所有警报
	alarm list			    Lists all alarms				# 列出所有警报
	auth disable			Disables authentication			# 关闭认证
	auth enable			    Enables authentication			# 启用认证
	auth status				Returns authentication status	# 返回认证状态
	check datascale			Check the memory usage of holding data for different workloads on a given server endpoint.					 # 检查在给定服务器端点上保存不同工作负载的数据的内存使用情况
	check perf				Check the performance of the etcd cluster	# 检查集群间性能
	compaction				Compacts the event history in etcd			# 在etcd中压缩事件历史
	defrag					Defragments the storage of the etcd members with given endpoints	
							# 对给定端点的etcd成员的存储进行碎片整理
	del						Removes the specified key or range of keys [key, range_end)
							# 删除指定的键或键的范围 [key, range_end)
	elect					Observes and participates in leader election
							# 观察并参与领导选举
	endpoint hashkv			Prints the KV history hash for each endpoint in --endpoints
							# 打印 “——endpoint=[127.0.0.1:2379]” 中每个端点的KV历史哈希值
	endpoint health			Checks the healthiness of endpoints specified in `--endpoints` flag
							# 检查在 “——endpoint=[127.0.0.1:2379]” 标志中指定的端点的健康状态
	endpoint status			Prints out the status of endpoints specified in `--endpoints` flag
							# 打印出在“——endpoints” 标志中指定的端点的状态 
	get						Gets the key or a range of keys
							# 获取键或键的范围
	help					Help about any command
							# 关于任何命令的帮助
	lease grant				Creates leases
							# 创建图层（create layer）
	lease keep-alive		Keeps leases alive (renew)
							# 保持租约有效(续租)
	lease list				List all active leases
							# 列出所有有效租约
	lease revoke			Revokes leases
							# 撤销租赁
	lease timetolive		Get lease information
							# 获得租赁信息
	lock					Acquires a named lock
							# 获取命名锁
	make-mirror				Makes a mirror at the destination etcd cluster
							# 在目标etcd集群上创建镜像
	member add				Adds a member into the cluster
							# 向集群中添加成员
	member list				Lists all members in the cluster
							# 列出集群中的所有成员
	member promote			Promotes a non-voting member in the cluster
							# 在集群中提升一个无投票权的成员
	member remove			Removes a member from the cluster
							# 从集群中移除成员
	member update			Updates a member in the cluster
							# 更新集群中的成员
	move-leader				Transfers leadership to another etcd cluster member.
							# 将领导权移交给etcd集群的另一个成员
	put						Puts the given key into the store
							# 将给定的键放入存储中
	role add				Adds a new role
							# 添加一个新角色
	role delete				Deletes a role
							# 删除一个角色
	role get				Gets detailed information of a role
							# 获取角色的详细信息
	role grant-permission	Grants a key to a role
							# 授予角色一个密钥
	role list				Lists all roles
							# 列出所有角色
	role revoke-permission	Revokes a key from a role
							# 从角色中撤销一个密钥
	snapshot restore		Restores an etcd member snapshot to an etcd directory
							# 将 etcd 成员快照恢复到 etcd 目录
	snapshot save			Stores an etcd node backend snapshot to a given file
							# 将 etcd 节点后端快照存储到给定的文件
	snapshot status			[deprecated] Gets backend snapshot status of a given file
							# [即将弃用] 获取给定文件的后端快照状态	（etcdutl snapshot status）
	txn						Txn processes all the requests in one transaction
							# Txn在一个事务中处理所有请求
	user add				Adds a new user
							# 添加新用户
	user delete				Deletes a user
							# 删除一个用户
	user get				Gets detailed information of a user
							# 获取用户的详细信息
	user grant-role			Grants a role to a user
							# 将角色授予用户
	user list				Lists all users
							# 列出所有用户
	user passwd				Changes password of user
							# 修改用户密码
	user revoke-role		Revokes a role from a user
							# 撤销用户的角色
	version					Prints the version of etcdctl
							# 打印etcdctl的版本
	watch					Watches events stream on keys or prefixes
							# 监视键或前缀上的事件流

OPTIONS:
      --cacert=""						verify certificates of TLS-enabled secure servers using this CA bundle
      									# 使用此CA包验证启用tls的安全服务器的证书
      --cert=""							identify secure client using this TLS certificate file
      									# 使用此TLS证书文件识别安全客户端
      --command-timeout=5s				timeout for short running command (excluding dial timeout)
      									# 短时间运行命令超时(不包括拨号超时)
      --debug[=false]					enable client-side debug logging
      									# 启用客户端调试日志记录 [=false]
      --dial-timeout=2s					dial timeout for client connections
      									# 拨号客户端连接超时
  -d, --discovery-srv=""				domain name to query for SRV records describing cluster endpoints
	  									# 查询描述集群端点的 SRV 记录的域名
      --discovery-srv-name=""			service name to query when using DNS discovery
      									# 
      --endpoints=[127.0.0.1:2379]		gRPC endpoints
      									# 指定端点
  -h, --help[=false]					help for etcdctl
      --hex[=false]						print byte strings as hex encoded strings
      									# 以十六进制编码的字符串输出字节串
      --insecure-discovery[=true]		accept insecure SRV records describing cluster endpoints
      									# 接受描述集群端点的不安全SRV记录
      --insecure-skip-tls-verify[=false]	skip server certificate verification
											(CAUTION: this option should be enabled only for testing purposes)
										# 跳过服务器证书验证。注意:此选项只能用于测试目的
      --insecure-transport[=true]	disable transport security for client connections
      									# 为客户端连接禁用传输安全性
      --keepalive-time=2s			keepalive time for client connections
      									# 客户端连接的存活时间
      --keepalive-timeout=6s		keepalive timeout for client connections
      									# 客户端连接的 Keepalive 超时
      --key=""						identify secure client using this TLS key file
      									# 使用此TLS密钥文件识别安全客户端
      --password=""					password for authentication (if this option is used, \
									--user option shouldn't include password)
										# 身份验证的密码（如果使用了这个选项，——user选项不应该包含密码）
      --user=""						username[:password] for authentication (prompt if password is not supplied)
      									# 用于身份验证 (如果没有提供密码将提示)
  -w, --write-out="simple"			set the output format (fields, json, protobuf, simple, table)
  										# 设置输出格式(fields, json, protobuf, simple, table)
```

##  key 操作

### 查询

```bash
root@k8s-etcd-1:~$ etcdctl get / --prefix --keys-only	# 以路径的方式获取所有 key 信息

# pod 信息
root@k8s-etcd-1:~$ etcdctl get / --prefix --keys-only|grep pod
/calico/ipam/v2/handle/k8s-pod-network.290cc598..c99f9aab
/calico/ipam/v2/handle/k8s-pod-network.5f3035e6..6d578a88
...

# namespace 信息
root@k8s-etcd-1:~$ etcdctl get / --prefix --keys-only|grep namespace
..
/registry/namespaces/default
/registry/namespaces/kube-node-lease
/registry/namespaces/kube-public
/registry/namespaces/kube-system
..

# 控制器
root@k8s-etcd-1:~$ etcdctl get / --prefix --keys-only|grep deployment
..
/registry/clusterrolebindings/system:controller:deployment-controller
/registry/clusterroles/system:controller:deployment-controller
/registry/deployments/kube-system/calico-kube-controllers
/registry/deployments/kube-system/coredns
..

# calico 组件信息
root@k8s-etcd-1:~$ etcdctl get / --prefix --keys-only|grep calico
..
/calico/ipam/v2/handle/ipip-tunnel-addr-k8s-master-1
/calico/ipam/v2/handle/ipip-tunnel-addr-k8s-master-2
/calico/ipam/v2/handle/ipip-tunnel-addr-k8s-node-1
/calico/ipam/v2/handle/ipip-tunnel-addr-k8s-node-2
..
```

### 增加

```bash
root@k8s-etcd-1:~$ etcdctl put /name "clemente"
OK
root@k8s-etcd-1:~$ etcdctl get /name
/name
clemente
```

### 改动

```bash
# 直接覆盖就是更新数据
root@k8s-etcd-1:~$ etcdctl put /name "clemente-jiao"
OK
root@k8s-etcd-1:~$ etcdctl get /name
/name
clemente-jiao

```

### 删除

```bash
root@k8s-etcd-1:~$ etcdctl del /name
1
root@k8s-etcd-1:~$ etcdctl get /name
# 空
```



## 健康状态检查

```bash
# endpoint health, --endpoints
# 纯命令方式: 注意以下应为一行！"\" 换行只为方便修改和展示
root@k8s-etcd-1:~$ etcdctl endpoint health -w table member list\
--endpoints=https://192.168.11.16:2379 \
--endpoints=https://192.168.11.17:2379 \
--endpoints=https://192.168.11.18:2379 \
--cacert=/etc/kubernetes/ssl/ca.pem \
--cert=/etc/kubernetes/ssl/etcd.pem \
--key=/etc/kubernetes/ssl/etcd-key.pem 

# 循环获取状态
root@k8s-etcd-1:~$ export NODE_IPS="192.168.11.16 192.168.11.17 192.168.11.18"
root@k8s-etcd-1:~$ for ip in ${NODE_IPS}; do \
/usr/bin/etcdctl endpoint health \
--endpoints=https://${ip}:2379 \
--cacert=/etc/kubernetes/ssl/ca.pem \
--cert=/etc/kubernetes/ssl/etcd.pem \
--key=/etc/kubernetes/ssl/etcd-key.pem; \
done

# 检查leader状态：-w table 【member list】/【endpoint status】
root@k8s-etcd-1:~$ etcdctl -w table member list \
--endpoints=https://192.168.11.16:2379 \
--endpoints=https://192.168.11.17:2379 \
--endpoints=https://192.168.11.18:2379 \
--cacert=/etc/kubernetes/ssl/ca.pem \
--cert=/etc/kubernetes/ssl/etcd.pem \
--key=/etc/kubernetes/ssl/etcd-key.pem


```

## 备份与恢复

### v2版本

```bash
ETCDCTL_API=2 etcdctl backup --data-dir /var/lib/etcd --backup-dir /opt/etcd_backup-2022-01-29
```

### v3版本

```bash
# 备份数据
ETCDCTL_API=3 etcdctl snapshot save snapshot.db

# 将数据恢复到一个新的不存在的目录中
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db --data-dir=/opt/etcd-testdir

# 自动备份数据
mkdir -p /data/etcd-backup-dir
cat script.sh
	#!/bin/bash
    source /etc/profile
    DATE=`date +%Y-%m-%d_%H-%M-%S`
    ETCDCTL_API=3 /usr/bin/etcdctl snapshot save /data/etcd-backup-dir/etcd-snapshop-${DATA}.db
```

### 预写入日志

WAL： write ahead log 的缩写，是在执行真正的写操作之前先写一个日志，预写日志，

WAL：存放预写日志，最大的作用是记录了整个数据变化的全部历程。在 etcd 中，所有数据的修改在提交前，都要先写入到 WAL中。

### ETCD 恢复流程

```bash
当 etcd 集群宕机数量超过集群总节点数一半以上的时候(如总数为三台宕机两台)，就会导致整个集群宕机，后期需要重新恢复数据，
数据恢复流程如下：
1. 恢复服务器系统
2. 重新部署 etcd 集群
3. 停止 kube-apiserver、controller-manager、scheduler、kubelet、kube-proxy
4. 停止 etcd 集群
5. 各 etcd 节点恢复同一份备份数据
6. 启动各节点并验证 etcd 集群
7. 启动 kube-apiserver、controller-manager、scheduler、kubelet-kube-proxy
8. 验证 k8s master 状态及 pod 数据
```





