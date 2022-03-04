[toc]

## 四表五链之间的对应关系

|表(tables)|INPUT(入)|FORWARD(转发)|OUTPUT(出)|PREROUTING|POSTROUTING|
|:------:|:---:|:---:|:---:|:---:|:---:|
|filter※|  √  |  √  |  √  |  ○  |  ○  |
|nat※   |  ○  |  ○  |  √  |  √  |  √  |
|mangle  |  √  |  √  |  √  |  √  |  √  |
|raw     |  √  |  √  |  √  |  √  |  √  |

iptables注解：**所有链名要大写**
|tables|chains|注解|
|:--:|:--|:--|
|filter   | |强调：主要和主机自身有关，真正负责主机防火墙功能的（过滤流入流出主机的数据包）。<br>filter表是iptables默认使用的表。这个表定义了三个链（chains）：<br>企业工作场景：主机防火墙|
| |INPUT  |负责过滤所有目标地址是是本机地址的数据包。通俗的讲，就是过滤进入主机的数据包|
| |FORWRAD|负责转发流经主机的数据包。起转发作用，和nat关系很大，后面会介绍。LVS NAT模式。net.ipv4.ip_forwrad=0|
| |OUTPUT |处理所有源地址是主机地址的数据包，通俗的讲，就是处理从主机发出去的数据包。|
| |强调： |对于filter表的控制是我们实现本机防火墙功能的重要手段，特别是对INPUT链的控制。|
|nat表   | |负责网络地址转换，即来源于目的ip地址和port的转换。应用：和主机本身无关。一般用于局域网共享上网或者特殊的端口转换服务相关。<br>nat功能一般企业工作场景<br>1. 用于做企业路由(zebra)或网关(iptables)，共享上网(POSTROUTING)<br>2. 做内部外部ip地址一对一映射(dmz)，硬件防火墙映射ip到内部服务器，例如ftp服务(PREROUTING)<br>3. web，单个端口的映射，直接映射80端口(PREROUTING)。这个表定义了三个链(chains),nat功能就相当于网络的acl控制。和网络交换机acl类似。
| |OUTPUT|和主机发出去的数据包有关。改变主机发出数据包的目标地址。|
| |PREROUTING|在数据包到达防火墙时进行路由判断之前执行的规则,作用是改变数据包的目的地址、目的端口等。(通俗比喻,就是收信时,根据规则重新收件人的地址。)<br>例如:把公网ip:1.0.0.1 映射到局域网的192.168.1.9服务器上。如果是web服务，可以把80转为局域网的服务器上9000端口。

小结：
1. 防火墙是层层过滤的。实际是按照配置规则的顺序从上到下，从前到后进行过滤的。
2. **如果匹配上规则**，即明确表明是阻止还是通过，数据包就不在往下匹配新规则了。
3. 如果规则中没有明确表明是阻止还是通过，也就是没有匹配规则，向下进行匹配，直到**匹配默认规则**得到明确的阻止还是通过。
4. 防火墙默认规则是**对应链的所有的规则**执行完才会执行的。
```markdown
提示：
iptables 防火钱规则的执行顺序是默认从前到后(从上到下)依次执行，
遇到匹配的规则就不在继续向下检查，只有遇到不匹配的规则才会继续向下进行匹配。
**重点：匹配上了拒绝规则也是匹配，这点需要多多注意。**
```
```bash
[root@localhost~]$ iptables -A INPUT -p tcp --dport 3306 -j DROP
[root@localhost~]$ iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
```
此时 telnet 192.168.1.9 3306 是不通的，原因就是 telnet 的请求已经匹配上了拒绝规则 iptables -A INPUT -p tcp --dport 3306 -j DROP，因此不会在找下面的规则匹配列。

如果希望 telnet 连通，可以把ACCEPT规则中的-A 改为 -I，即 `iptables -I INPUT -p tcp --dport 3306 -j DROP`
把允许规则放于 INPUT 链的第一行生效。
**默认规则是所有的规则执行完才会执行的。**

### 实际测试 iptables规则
#### 1.启动查看 iptables 规则状态

`iptables -L -n` 或 `iptables -L -n -v -x`
提示：如果遇到无法启动 iptables 的情况，解决方法为：`setup -> Firewall configuration -> enable`

iptables 在CentOS7_64中默认加载的内核模块
```bash
[root@localhost ~]$ lsmod | egrep "net|filter"
ip6t_rpfilter          12595  1
ebtable_filter         12827  1
ebtables               35009  3 ebtable_broute,ebtable_nat,ebtable_filter
ip6table_filter        12815  1
ip6_tables             26912  5 ip6table_filter,ip6table_mangle,ip6table_security,ip6table_nat,ip6table_raw
iptable_filter         12810  1
ip_tables              27126  5 iptable_security,iptable_filter,iptable_mangle,iptable_nat,iptable_raw
nfnetlink              14490  1 ip_set
vmxnet3                58059  0
```

加载模块到 linux 内核：
```bash
modprobe ip_tables
modprobe iptables_filter
modprobe iptables_nat
modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
modprobe ip_state
```
#### 2.清除默认规则

```bash
iptables --flush/-F   # 清除所有规则，不会处理默认的规则。
iptables -X   # 蟮用户自定义的链
iptables -Z   # 链的计数器清零。
```
#### 3.禁止规则

禁止 ssh 端口

```bash
# 找出当前机器ssh端口
[root@weibo-crawler ~]$ netstat -pantu| grep ssh
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      21711/sshd
tcp        0     52 192.168.11.6:22         192.168.11.213:5245     ESTABLISHED 21007/sshd: root@pt
tcp6       0      0 :::22                   :::*                    LISTEN      21711/sshd

# 禁止掉当前ssh端口，这里是22。
# 语法：
iptables -t [table] -[A(增加)D(删除)] chain rule-specification [options]

# 具体命令
iptables -t filter  -A INPUT -p tcp  --dport 22 -j  DROP

# 注释
1. iptables 默认用的就是filter表，因此 -t filter 可以省略。
2. 其中的 INPUT 和 DROP 要大写。
3. --jump   -j target

    target for rule (may load target extension)
# 基本的处理行为： ACCEPT(接受)、DROP(丢弃)、REJECT(拒绝)
4. 命令执行的规则，只在内存中临时生效。

```

## 使用示例

#### 第一步：开启系统的转发功能

```bash
vi /etc/sysctl.conf

#将 net.ipv4.ip_forward=0
#修改成
net.ipv4.ip_forward=1

# 编辑后使用命令让配置马上生效
sysctl -p
```

#### 第二步： iptables 的命令

```bash
iptables -t nat -A PREROUTING -p tcp --dport [端口号] -j DNAT --to-destination [目标IP]
iptables -t nat -A PREROUTING -p udp --dport [端口号] -j DNAT --to-destination [目标IP]
iptables -t nat -A POSTROUTING -p tcp -d [目标IP] --dport [端口号] -j SNAT --to-source [本地服务器IP]
iptables -t nat -A POSTROUTING -p udp -d [目标IP] --dport [端口号] -j SNAT --to-source [本地服务器IP]
```

#### 第三步：重启

重启 iptables 使配置生效(仅适合Centos6，7默认没有安装iptables防火墙，Debian/Ubuntu 不需要输入这个命令)

```bash
service iptables save
service iptables restart
```

### 扩展需求

#### 多端口转发

多端口转发修改方案： ( 将本地服务器的 50000~65535 转发至目标 IP 为 1.1.1.1 的 50000~65535 端口 )

```bash
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 50000:65535 -j DNAT --to-destination 1.1.1.1
iptables -t nat -A PREROUTING -p udp -m udp --dport 50000:65535 -j DNAT --to-destination 1.1.1.1
iptables -t nat -A POSTROUTING -d 1.1.1.1 -p tcp -m tcp --dport 50000:65535 -j SNAT --to-source [本地服务器IP]
iptables -t nat -A POSTROUTING -d 1.1.1.1 -p udp -m udp --dport 50000:65535 -j SNAT --to-source [本地服务器IP]
```

#### 非同端口号

非同端口号修改方案：（使用本地服务器的 60000 端口来转发目标 IP 为 1.1.1.1 的 50000 端口）

```bash
iptables -t nat  -A PREROUTING -p tcp -m tcp --dport 60000 -j DNAT --to-destination 1.1.1.1:50000
iptables -t nat  -A PREROUTING -p udp -m udp --dport 60000 -j DNAT --to-destination 1.1.1.1:50000
iptables -t nat  -A POSTROUTING -d 1.1.1.1 -p tcp -m tcp --dport 50000 -j SNAT --to-source [本地服务器IP]
iptables -t nat  -A POSTROUTING -d 1.1.1.1 -p udp -m udp --dport 50000 -j SNAT --to-source [本地服务器IP]
```

#### 查看 NAT 规则

```bash
iptables -t nat -vnL
```

#### 删除 NAT 规则

通过上面的查看规则命令，查看规则后，确定你要删除的规则的顺序，下面的命令是删除第一个规则。

```bash
iptables -t nat -D POSTROUTING 1
iptables -t nat -D PREROUTING 1
```

#### 保存规则

保存 iptables 规则并开机自动配置（Debian / Ubuntu）

```bash
iptables-save > /etc/iptables-rules-ipv4

# 最后，我们需要编辑/etc/network/interfaces文件

vi /etc/network/interfaces

# 在最后加入下面一行

pre-up iptables-restore < /etc/iptables-rules-ipv4
```

## 参考资料：

https://www.cnblogs.com/ccuc/p/7497440.html





















