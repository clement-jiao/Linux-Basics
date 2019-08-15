<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-13 23:39:32
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-14 13:22:10
 -->
##dnsmasq&安装&配置&详解

- [dnsmasq中文文档](https://wiki.archlinux.org/index.php/Dnsmasq_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87\))
- [dnsmasq详解](https://cloud.tencent.com/developer/article/1174717)
- [[DNSmasq] 安装&配置详解](https://moe.best/linux-memo/dnsmasq.html)
###安装
>`yum install -y dnsmasq`

###dnsmasq的解析流程
dnsmasq 先去解析**hosts**文件， 再去解析 /etc/dnsmasq.d/ 下的*.conf文件，并且这些文件的优先级要高于dnsmasq.conf，我们自定义的 resolv.dnsmasq.conf 中的DNS也被称为上游DNS，这是最后去查询解析的；

>**hosts > /etc/dnsmasq.d/*.conf > dnsmasq.conf > resolv.dnsmasq.conf**

如果不想用hosts文件做解析，我们可以在/etc/dnsmasq.conf中加入no-hosts这条语句，这样的话就直接查询上游DNS了，如果我们不想做上游查询，就是不想做正常的解析，我们可以加入no-reslov这条语句。
> **禁止hosts : /etc/dnsmasq.conf -> no-hosts**

> **禁止/etc/resolv.conf : /etc/dnsmasq.conf -> no-reslov**

###dnsmasq的参数及常用设置说明

|具体参数|参数说明|
|:----:|:-----:|
|resolv-file | 定义dnsmasq从哪里获取上游DNS服务器的地址， 默认从/etc/resolv.conf获取。|
|strict-order|表示严格按照resolv-file文件中的顺序从上到下进行DNS解析，直到第一个解析成功为止。|
|listen-address|定义dnsmasq监听的地址，默认是监控本机的所有网卡上。|
|address|启用泛域名解析，即自定义解析a记录，例如：address=/long.com/192.168.115.10 访问long.com时的所有域名都会被解析成192.168.115.10|
|bogus-nxdomain|对于任何被解析到此 IP 的域名，将响应 NXDOMAIN 使其解析失效，可以多次指定通常用于对于访问不存在的域名，禁止其跳转到运营商的广告站点|
|server|指定使用哪个DNS服务器进行解析，对于不同的网站可以使用不同的域名对应解析。例如：server=/google.com/8.8.8.8    #表示对于google的服务，使用谷歌的DNS解析。|



###配置上游服务器地址
resolv-file配置Dnsmasq额外的上游的DNS服务器，如果不开启就使用Linux主机默认的/etc/resolv.conf里的nameserver。
- 通过下面的选项指定其他文件来管理上游的DNS服务器
  ```bash
  $ vi /etc/dnsmasq.conf

  resolv-file=/etc/resolv.dnsmasq.conf
  ```
- 在指定文件中增加转发DNS的地址
  ```bash
  $ vi /etc/resolv.dnsmasq.conf

  nameserver 8.8.8.8
  nameserver 8.8.4.4
  ```
- 本地启用Dnsmasq解析
  ```bash
  $ vi /etc/resolv.conf

  nameserver 127.0.0.1
  ```
- 添加解析记录
  使用系统默认hosts
  编辑hosts文件,简单列举一下格式
  ```bash
  $ vi /etc/hosts

  127.0.0.1  localhost
  192.168.101.107   web01.mike.com web01
  192.168.101.107   web02.mike.com web02
  ```
  >hosts文件的强大之处还在于能够劫持解析，譬如mirror.centos.org是CentOS仓库所在，几乎是机器正常必访问一个域名，我将它解析成一个内网地址，搭建一个内网镜像站，不仅内网机器也可以及时得到安全更新，每月还可以节省很多流量。
- 使用自定义hosts文件
  1. 修改配置，增加自定义hosts文件位置。
    ```bash
    $ vi /etc/dnsmasq.conf

    addn-hosts=/etc/dnsmasq.hosts
    ```
  2. 在/etc/dnsmasq.hosts文件中添加DNS记录
    ```bash
    $ vi /etc/dnsmasq.hosts

    192.168.101.107   web01.mike.com    web01
    192.168.101.107   web02.mike.com    web02
    ```
- 使用自定义conf
  ```bash
  $ vi /etc/dnsmasq.d/address.conf

  # 指定dnsmasq默认查询的上游服务器，此处以Google Public DNS为例。
  server=8.8.8.8
  server=8.8.4.4

  # 把所有.cn的域名全部通过114.114.114.114这台国内DNS服务器来解析
  server=/cn/114.114.114.114

  # 给*.apple.com和taobao.com使用专用的DNS
  server=/taobao.com/223.5.5.5
  server=/.apple.com/223.5.5.5

  # 把www.hi-linux.com解析到特定的IP
  address=/www.hi-linux.com/192.168.101.107

  在这里hi-linux.com相当于*.mike.com泛解析
  address=/hi-linux.com/192.168.101.107
  ```
  >注：也可以直接添加到/etc/dnsmasq.conf中,不过/etc/dnsmasq.d/*.conf的优先级大于/etc/dnsmasq.conf。

###修改iptables配置
- 允许本机的53端口可对外访问
  ```bash
  $ iptables -A INPUT -p udp -m udp --dport 53 -j ACCEPT
  $ iptables -A INPUT -p tcp -m tcp --dport 53 -j ACCEPT
  ```
- 转发DNS请求
  ```bash
  # 开启流量转发功能
  $ echo '1' > /proc/sys/net/ipv4/ip_forward
  $ echo '1' > /proc/sys/net/ipv6/ip_forward   # IPv6 用户选用

  # 添加流量转发规则，将外部到53的端口的请求映射到Dnsmasq服务器的53端口
  $ iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
  $ iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53

  # 如果要限制只允许内网的请求，方法如下
  $ iptables -t nat -A PREROUTING -i eth1 -p upd --dport 53 -j REDIRECT --to-port 53
  ```
- 保存规则并重启
  ```bash
  $ service iptables save
  $ service iptables restart
  ```



###一些Dnsmasq技巧

####检查配置文件语法

```bash
[root@localhost ~]# dnsmasq -test
dnsmasq: syntax check OK.
```

####Dnsmasq性能优化:
>我们都知道Bind不配合数据库的情况下，经常需要重新载入并读取配置文件，这是造成性能低下的原因。
根据这点教训，我们可以考虑不读取/etc/hosts文件。而是另外指定一个在共享内存里的文件，比如/dev/shm/dnsrecord.txt ，这样就不费劲了，又由于内存的非持久性，重启就消失，可以定期同步硬盘上的某个内容到内存文件中。
具体实现步骤:

- 配置dnsmasq
  ```bash
  $ vim /etc/dnsmasq.conf

  no-hosts
  addn-hosts=/dev/shm/dnsrecord.txt
  ```
- 解决同步问题
  ```bash
  开机启动
  $ echo "cat /etc/hosts > /dev/shm/dnsrecord.txt" >>/etc/rc.local
  # 定时同步内容
  $ crontab -e
  */10 * * * * cat /etc/hosts > /dev/shm/dnsrecord.txt
  ```

####Dnsmasq快速选择上游DNS服务器
经常会有这样的情景，Dnsmasq服务器配了一堆上游服务器，转发本地的dns请求，缺省是Dnsmasq事实上是只挑了一个上游dns服务器来查询并转发结果，这样如果选错服务器的话会导致DNS响应变慢。
解决方法:
```bash
$ vi /etc/dnsmasq.conf

all-servers
server=8.8.8.8
server=219.141.136.10
```

all-servers表示对以下设置的所有server发起查询，选择回应最快的一条作为查询结果返回。
上面我们设置了两个dns server，8.8.8.8(谷歌dns)和219.141.136.10(移动的dns)，会同时查询这两个服务器，询问dns地址谁返回快就采用谁的结果。

####dnsmasq-china-list项目
dnsmasq-china-list项目维护了一张国内常用但是通过国外DNS会解析错误的网站域名的列表，保证List中的国内域名全部走国内DNS服务器解析。

项目地址: [https://github.com/felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)

dnsmasq-china-list使用

- 取消dnsmasq.conf里conf-dir=/etc/dnsmasq.d这一行的注释
- 获取项目文件
- 将accelerated-domains.china.conf, bogus-nxdomain.china.conf,google.china.conf(可选)放到/etc/dnsmasq.d/目录下(如目录不存在则建立一个)。
- 将dnsmasq-update-china-list放到/usr/bin/，这是一个批量修改DNS服务器的工具(可选)。

`$ git clone https://github.com/felixonmars/dnsmasq-china-list.git`


##dnsmasq配置文件
注解时间：2019年08月12日02:17:36
更新至405行
```conf
# Configuration file for dnsmasq.
# dnsmasq 配置文件
#
# Format is one option per line, legal options are the same
# as the long options legal on the command line. See
# "/usr/sbin/dnsmasq --help" or "man 8 dnsmasq" for details.
# 格式是每行一个选项，合法选项与命令行上的长选项合法相同。
# 有关详细信息，请参阅“/ usr / sbin / dnsmasq --help”或“man 8 dnsmasq”。


# Listen on this specific port instead of the standard DNS port
# (53). Setting this to zero completely disables DNS function,
# leaving only DHCP and/or TFTP.
# 侦听此特定端口而不是标准DNS端口（53）。
# 将此设置为零将完全禁用DNS功能，仅保留DHCP和/或TFTP。
#port=5353

# The following two options make you a better netizen, since they
# tell dnsmasq to filter out queries which the public DNS cannot
# answer, and which load the servers (especially the root servers)
# unnecessarily. If you have a dial-on-demand link they also stop
# these requests from bringing up the link unnecessarily.

# 以下两个选项使您成为更好的网友，因为它们告诉dnsmasq过滤掉公共DNS无法回答的查询，
# 以及不必要地加载服务器（尤其是根服务器）的查询。 如果您有按需拨号链接，他们也会阻止这些请求不必要地显示链接。
# {大体来讲就是：1.哪些公共DNS没有回答 2.哪些root根域不可达。}


# Never forward plain names (without a dot or domain part)
# 永远不要转发普通名称（没有点或域部分）{格式错误的域名}
#domain-needed

# Never forward addresses in the non-routed address spaces.
# 切勿转发非路由地址空间中的地址。{不在路由地址中的域名}
#bogus-priv

# Uncomment these to enable DNSSEC validation and caching:
# (Requires dnsmasq to be built with DNSSEC option.)
# 取消注释以启用DNSSEC验证和缓存：（需要使用DNSSEC选项构建dnsmasq。）
#conf-file=%%PREFIX%%/share/dnsmasq/trust-anchors.conf
#dnssec

# Replies which are not DNSSEC signed may be legitimate, because the domain
# is unsigned, or may be forgeries. Setting this option tells dnsmasq to
# check that an unsigned reply is OK, by finding a secure proof that a DS
# record somewhere between the root and the domain does not exist.
# The cost of setting this is that even queries in unsigned domains will need one or more extra DNS queries to verify.
# 因为域名未签名，未签署DNSSEC的回复可能是合法的，或者可能是伪造的。
# 设置此选项会通过查找根目录和域之间某处的DS记录不存在的安全证据来告知dnsmasq检查未签名的答复是否正常。
# 设置此成本的成本是，即使是未签名域中的查询，也需要一个或多个额外的DNS查询来验证。
#dnssec-check-unsigned

# Uncomment this to filter useless windows-originated DNS requests
# which can trigger dial-on-demand links needlessly.
# Note that (amongst other things) this blocks all SRV requests,
# so don't use it if you use eg Kerberos, SIP, XMMP or Google-talk.
# This option only affects forwarding, SRV records originating for
# dnsmasq (via srv-host= lines) are not suppressed by it.
# 取消注释以过滤无用的Windows发起的DNS请求，这些请求可以不必要地触发按需拨号链接。
# 请注意（除此之外）这会阻止所有SRV请求，因此如果您使用例如Kerberos，SIP，XMMP或Google-talk，请不要使用它。
# 此选项仅影响转发，源自dnsmasq的SRV记录（通过srv-host = lines）不会被它抑制。
#filterwin2k

# Change this line if you want dns to get its upstream servers from
# somewhere other that /etc/resolv.conf
# 如果您希望dns从/etc/resolv.conf以外的某个位置获取其上游服务器，请更改此行。
# 如果不开启就使用默认的/etc/resolv.conf里的nameserver，通过下面选项指定他的文件。
resolv-file=/etc/resolv.dnsmasq.conf

# By  default,  dnsmasq  will  send queries to any of the upstream
# servers it knows about and tries to favour servers to are  known
# to  be  up.  Uncommenting this forces dnsmasq to try each query
# with  each  server  strictly  in  the  order  they   appear   in
# /etc/resolv.conf
# 默认情况下，dnsmasq 将向其知道的任何上游服务器发送查询，并尝试使用已知的服务器。
# 取消注释这会强制 dnsmasq 严格按照它们在 /etc/resolv.conf 中出现的顺序尝试每个查询服务器的每个查询。{resolv.conf的顺序查询}
#strict-order

# If you don't want dnsmasq to read /etc/resolv.conf or any other
# file, getting its servers from this file instead (see below), then
# uncomment this.
# 如果您不希望 dnsmasq 读取 /etc/resolv.conf 或任何其他文件，请从此文件中获取其服务器（请参阅下文），然后取消注释。
# {只读取本文件，不再读取其他配置文件：resolv、hosts等}
#no-resolv

# If you don't want dnsmasq to poll /etc/resolv.conf or other resolv
# files for changes and re-read them then uncomment this.
# 如果您不希望dnsmasq轮询/etc/resolv.conf或
# 其他resolv文件进行更改并重新读取它们，请取消注释。
#no-poll

# Add other name servers here, with domain specs if they are for
# non-public domains.
# 在此处添加其他域名服务器，如果它们适用于非公共域，则使用域规范。{一般用于内网域名}
#server=/localnet/192.168.0.1
server=/web.jdf.lan/192.168.111.2

# Example of routing PTR queries to nameservers: this will send all
# address->name queries for 192.168.3/24 to nameserver 10.1.2.3
# 将PTR查询路由到域名服务器的示例：这会将192.168.3/24的所有地址 -> 名称查询发送到域名服务器10.1.2.3
# {设置一个反向解析，所有192.168.3.0/24的地址都到10.1.2.3去解析}
#server=/3.168.192.in-addr.arpa/10.1.2.3

# Add local-only domains here, queries in these domains are answered
# from /etc/hosts or DHCP only.
# 在此处添加仅限本地的域，这些域中的查询仅从/etc/hosts 或DHCP回答。
# {增加一个本地域名，会在/etc/hosts中进行查询}
#local=/localnet/

# Add domains which you want to force to an IP address here.
# The example below send any host in double-click.net to a local
# web-server.
# 在此处添加要强制为IP地址的域。 以下示例将double-click.net中的任何主机发送到本地Web服务器。
# {增加一个域名，强制解析到你指定的地址上}
#address=/double-click.net/127.0.0.1

# --address (and --server) work with IPv6 addresses too.
# --address（和--server）也可以使用IPv6地址。
#address=/www.thekelleys.org.uk/fe80::20d:60ff:fe36:f83

# Add the IPs of all queries to yahoo.com, google.com, and their
# subdomains to the vpn and search ipsets:
# 将所有查询的IP添加到yahoo.com，google.com及其子域到vpn并搜索ipsets：
#ipset=/yahoo.com/google.com/vpn,search

# You can control how dnsmasq talks to a server: this forces
# queries to 10.1.2.3 to be routed via eth1
# 您可以控制dnsmasq如何与服务器通信：这会强制执行
# 查询要通过eth1路由到10.1.2.3
# {可以控制Dnsmasq和Server之间的查询从哪个网卡出去}
# server=10.1.2.3@eth1

# and this sets the source (ie local) address used to talk to
# 10.1.2.3 to 192.168.1.1 port 55 (there must be an interface with that
# IP on the machine, obviously).
# 这设置了用于与10.1.2.3到192.168.1.1端口55通信的源（即本地）地址
#（显然，机器上必须有一个具有该IP的接口）。
# {可以控制Dnsmasq和Server之间的查询从哪个网卡出去}
# server=10.1.2.3@192.168.1.1#55

# If you want dnsmasq to change uid and gid to something other
# than the default, edit the following lines.
# 如果您希望dnsmasq将uid和gid更改为默认值以外的其他内容，请编辑以下行。
# {改变Dnsmasq默认的uid和gid}
#user=
#group=

# If you want dnsmasq to listen for DHCP and DNS requests only on
# specified interfaces (and the loopback) give the name of the
# interface (eg eth0) here.
# Repeat the line for more than one interface.
# 如果您希望dnsmasq仅在指定的接口（和环回）上侦听DHCP和DNS请求，
# 请在此处提供接口的名称（例如eth0）。 对多个接口重复该行。
# {如果你想Dnsmasq监听某个端口为dhcp、dns提供服务}
interface=eth1
# Or you can specify which interface _not_ to listen on
# 或者您可以指定不要监听的接口
# {你还可以指定哪个端口你不想监听}
#except-interface=
# Or which to listen on by address (remember to include 127.0.0.1 if
# you use this.)
# 或者通过地址收听哪些（如果使用此地址，请记住包含127.0.0.1。）
# {设置想监听的地址，如果你本机要使用写上127.0.0.1。}
listen-address=192.168.111.1
# If you want dnsmasq to provide only DNS service on an interface,
# configure it as shown above, and then use the following line to
# disable DHCP and TFTP on it.
# 如果您希望dnsmasq仅在接口上提供DNS服务，请按上图所示进行配置，然后使用以下行禁用DHCP和TFTP。
# {如果你想在某个端口只提供dns服务，则可以进行配置禁止dhcp服务}
#no-dhcp-interface=

# On systems which support it, dnsmasq binds the wildcard address,
# even when it is listening on only some interfaces. It then discards
# requests that it shouldn't reply to. This has the advantage of
# working even when interfaces come and go and change address. If you
# want dnsmasq to really bind only the interfaces it is listening on,
# uncomment this option. About the only time you may need this is when
# running another nameserver on the same machine.
# 在支持它的系统上，dnsmasq绑定通配符地址，即使它只侦听某些接口。
# 然后它丢弃它不应该回复的请求。 即使接口来来去去改变地址，这也具有工作的优点。
# 如果您希望dnsmasq仅绑定它正在侦听的接口，请取消注释此选项。
# 关于您可能需要的唯一时间是在同一台计算机上运行另一个域名服务器。
#bind-interfaces

# If you don't want dnsmasq to read /etc/hosts, uncomment the
# following line.
# 如果您不希望dnsmasq读取/etc/hosts，请取消注释以下行。
# {如果你不想使用/etc/hosts，则取消下面的注释}
no-hosts
# or if you want it to read another file, as well as /etc/hosts, use
# this.
# 或者如果你想让它读取另一个文件，以及/etc/hosts，请使用它。
# {如果你项读取其他类似/etc/hosts文件，则进行配置}
#addn-hosts=/etc/banner_add_hosts

# Set this (and domain: see below) if you want to have a domain
# automatically added to simple names in a hosts-file.
# 如果要将域自动添加到hosts文件中的简单名称，请设置此（和域：见下文）。
# {自动的给hosts中的name增加一个域名}
#expand-hosts

# Set the domain for dnsmasq. this is optional, but if it is set, it
# does the following things.
# 为dnsmasq设置域。 这是可选的，但是如果设置它，它会执行以下操作。
# 1) Allows DHCP hosts to have fully qualified domain names, as long
#     as the domain part matches this setting.
# 允许DHCP主机具有完全限定的域名，只要域部分与此设置匹配即可。
# 2) Sets the "domain" DHCP option thereby potentially setting the
#    domain of all systems configured by DHCP
# 设置“域”DHCP选项，从而可能设置DHCP配置的所有系统的域
# 3) Provides the domain part for "expand-hosts"
# 为“expand-hosts”提供域部分
# {给dhcp服务赋予一个域名}
#domain=thekelleys.org.uk

# Set a different domain for a particular subnet
# 为特定子网设置不同的域
# {给dhcp的一个子域赋予一个不同的域名}
#domain=wireless.thekelleys.org.uk,192.168.2.0/24

# Same idea, but range rather then subnet
# {同上，不过子域是一个范围}
#domain=reserved.thekelleys.org.uk,192.68.3.100,192.168.3.200

# Uncomment this to enable the integrated DHCP server, you need
# to supply the range of addresses available for lease and optionally
# a lease time. If you have more than one network, you will need to
# repeat this for each network on which you want to supply DHCP
# service.
# {dhcp分发ip的范围，以及每个ip的租约时间}
dhcp-range=192.168.111.1,192.168.111.10,12h

# This is an example of a DHCP range where the netmask is given. This
# is needed for networks we reach the dnsmasq DHCP server via a relay
# agent. If you don't know what a DHCP relay agent is, you probably
# don't need to worry about this.
# 这是给出网络掩码的DHCP范围的示例。 这是我们通过中继代理到达dnsmasq DHCP服务器的网络所必需的。
# 如果您不知道DHCP中继代理是什么，您可能不需要担心这一点。
# {同上，不过给出了掩码}
#dhcp-range=192.168.0.50,192.168.0.150,255.255.255.0,12h

# This is an example of a DHCP range which sets a tag, so that
# some DHCP options may be set only for this network.
# 这是设置标记的DHCP范围的示例，因此可以仅为该网络设置一些DHCP选项。
#dhcp-range=set:red,192.168.0.50,192.168.0.150

# Use this DHCP range only when the tag "green" is set.
# 仅在设置了“绿色”标记时才使用此DHCP范围。
#dhcp-range=tag:green,192.168.0.50,192.168.0.150,12h

# Specify a subnet which can't be used for dynamic address allocation,
# is available for hosts with matching --dhcp-host lines. Note that
# dhcp-host declarations will be ignored unless there is a dhcp-range
# of some type for the subnet in question.
# In this case the netmask is implied (it comes from the network
# configuration on the machine running dnsmasq) it is possible to give
# an explicit netmask instead.
# 指定不能用于动态地址分配的子网，可用于具有匹配的--dhcp-host行的主机。
# 请注意，除非有相关子网的某种类型的dhcp-range，否则将忽略dhcp-host声明。
# 在这种情况下，隐含了网络掩码（它来自运行dnsmasq的计算机上的网络配置），可以提供明确的网络掩码。
#dhcp-range=192.168.0.0,static

# Enable DHCPv6. Note that the prefix-length does not need to be specified
# and defaults to 64 if missing/
# 启用DHCPv6。 请注意，不需要指定prefix-length，如果缺少/则默认为64
#dhcp-range=1234::2, 1234::500, 64, 12h

# Do Router Advertisements, BUT NOT DHCP for this subnet.
# 做路由器广告，但不是这个子网的DHCP。
#dhcp-range=1234::, ra-only

# Do Router Advertisements, BUT NOT DHCP for this subnet, also try and
# add names to the DNS for the IPv6 address of SLAAC-configured dual-stack
# hosts. Use the DHCPv4 lease to derive the name, network segment and
# MAC address and assume that the host will also have an
# IPv6 address calculated using the SLAAC algorithm.
# 做路由器广告，但不是该子网的DHCP，也尝试为DNS添加SLAAC配置的双栈主机的IPv6地址名称。
# 使用DHCPv4租约来获取名称，网段和MAC地址，并假设主机还将使用SLAAC算法计算IPv6地址。
#dhcp-range=1234::, ra-names

# Do Router Advertisements, BUT NOT DHCP for this subnet.
# Set the lifetime to 46 hours. (Note: minimum lifetime is 2 hours.)
# 做路由器广告，但不是这个子网的DHCP。 将生命周期设置为46小时。 （注意：最短寿命为2小时。）
#dhcp-range=1234::, ra-only, 48h

# Do DHCP and Router Advertisements for this subnet. Set the A bit in the RA
# so that clients can use SLAAC addresses as well as DHCP ones.
# 为此子网执行DHCP和路由器通告。 设置RA中的A位，以便客户端可以使用SLAAC地址和DHCP地址。
#dhcp-range=1234::2, 1234::500, slaac

# Do Router Advertisements and stateless DHCP for this subnet. Clients will
# not get addresses from DHCP, but they will get other configuration information.
# They will use SLAAC for addresses.
# 为此子网执行路由器通告和无状态DHCP。
# 客户端不会从DHCP获取地址，但是他们将获得其他配置信息。 他们将使用SLAAC作为地址。
#dhcp-range=1234::, ra-stateless

# Do stateless DHCP, SLAAC, and generate DNS names for SLAAC addresses
# from DHCPv4 leases.
# 为DHCPv4租约中的SLAAC地址执行无状态DHCP，SLAAC和生成DNS名称。
#dhcp-range=1234::, ra-stateless, ra-names

# Do router advertisements for all subnets where we're doing DHCPv6
# Unless overridden by ra-stateless, ra-names, et al, the router
# advertisements will have the M and O bits set, so that the clients
# get addresses and configuration from DHCPv6, and the A bit reset, so the
# clients don't use SLAAC addresses.
# 为我们正在进行DHCPv6的所有子网做路由器广告除非被ra-stateless，ra-names等覆盖，
# 否则路由器通告将设置M和O位，以便客户端从DHCPv6获取地址和配置，以及A位复位，因此客户端不使用SLAAC地址。
#enable-ra

# Supply parameters for specified hosts using DHCP. There are lots
# of valid alternatives, so we will give examples of each. Note that
# IP addresses DO NOT have to be in the range given above, they just
# need to be on the same network. The order of the parameters in these
# do not matter, it's permissible to give name, address and MAC in any
# order.
# 使用DHCP为指定主机提供参数。 有很多有效的替代方案，因此我们将举例说明。
# 请注意，IP地址不必在上面给出的范围内，它们只需要在同一网络上。
# 这些参数的顺序无关紧要，允许以任何顺序给出名称，地址和MAC。

# Always allocate the host with Ethernet address 11:22:33:44:55:66
# The IP address 192.168.0.60
# 始终使用以太网地址11：22：33：44：55：66分配主机IP地址192.168.0.60
# {按照Mac地址分配IP}
#dhcp-host=11:22:33:44:55:66,192.168.0.60
dhcp-host=08:00:27:b4:c2:15,192.168.111.2,web.jgf.lan

# Always set the name of the host with hardware address
# 始终使用硬件地址设置主机的名称
# 11:22:33:44:55:66 to be "fred"
#dhcp-host=11:22:33:44:55:66,fred

# Always give the host with Ethernet address 11:22:33:44:55:66
# the name fred and IP address 192.168.0.60 and lease time 45 minutes
# 始终给主机提供以太网地址11：22：33：44：55：66名称fred和IP地址192.168.0.60和租用时间45分钟
#dhcp-host=11:22:33:44:55:66,fred,192.168.0.60,45m

# Give a host with Ethernet address 11:22:33:44:55:66 or
# 12:34:56:78:90:12 the IP address 192.168.0.60. Dnsmasq will assume
# that these two Ethernet interfaces will never be in use at the same
# time, and give the IP address to the second, even if it is already
# in use by the first. Useful for laptops with wired and wireless
# addresses.
# 为主机提供以太网地址11：22：33：44：55：66或12：34：56：78：90：12 IP地址192.168.0.60。
# Dnsmasq将假设这两个以太网接口永远不会同时使用，并将IP地址提供给第二个，即使它已被第一个使用。
# 适用于有线和无线地址的笔记本电脑。
#dhcp-host=11:22:33:44:55:66,12:34:56:78:90:12,192.168.0.60

# Give the machine which says its name is "bert" IP address
# 192.168.0.70 and an infinite lease
# 给名称为“bert”IP地址192.168.0.70的机器和无限租约
#dhcp-host=bert,192.168.0.70,infinite

# Always give the host with client identifier 01:02:02:04
# the IP address 192.168.0.60
# 始终为主机提供客户端标识符01：02：02：04 IP地址192.168.0.60
#dhcp-host=id:01:02:02:04,192.168.0.60

# Always give the InfiniBand interface with hardware address
# 80:00:00:48:fe:80:00:00:00:00:00:00:f4:52:14:03:00:28:05:81 the
# ip address 192.168.0.61. The client id is derived from the prefix
# ff:00:00:00:00:00:02:00:00:02:c9:00 and the last 8 pairs of
# hex digits of the hardware address.
# 始终给InfiniBand接口提供硬件地址：
# 80：00：00：48：fe：80：00：00：00：00：00：00：f4：52：14：03：00：28：05：81
# ip地址：192.168.0.61。
# 客户端ID源自前缀：
# ff：00：00：00：00：00：02：00：00：02：c9：00 以及硬件地址的最后8对十六进制数字。
#dhcp-host=id:ff:00:00:00:00:00:02:00:00:02:c9:00:f4:52:14:03:00:28:05:81,192.168.0.61

# Always give the host with client identifier "marjorie"
# the IP address 192.168.0.60
# 始终为主机提供客户端标识符“marjorie”，IP地址为192.168.0.60
#dhcp-host=id:marjorie,192.168.0.60

# Enable the address given for "judge" in /etc/hosts
# to be given to a machine presenting the name "judge" when
# it asks for a DHCP lease.
# 在/etc/hosts中为“判断”提供的地址在它要求DHCP租约时被提供给名称为“judge”的机器。
#dhcp-host=judge

# Never offer DHCP service to a machine whose Ethernet
# address is 11:22:33:44:55:66
# 切勿向以太网地址为11：22：33：44：55：66的计算机提供DHCP服务
#dhcp-host=11:22:33:44:55:66,ignore

# Ignore any client-id presented by the machine with Ethernet
# address 11:22:33:44:55:66. This is useful to prevent a machine
# being treated differently when running under different OS's or
# between PXE boot and OS boot.
# 忽略机器提供的任何客户机ID，以太网地址为11：22：33：44：55：66。
# 这有助于防止在不同操作系统下运行或在PXE引导和操作系统引导之间对机器进行不同的处理。
#dhcp-host=11:22:33:44:55:66,id:*

# Send extra options which are tagged as "red" to
# the machine with Ethernet address 11:22:33:44:55:66
# 将标记为“红色”的额外选项发送到具有以太网地址11：22：33：44：55：66的机器
#dhcp-host=11:22:33:44:55:66,set:red

# Send extra options which are tagged as "red" to
# any machine with Ethernet address starting 11:22:33:
#dhcp-host=11:22:33:*:*:*,set:red

# Give a fixed IPv6 address and name to client with
# DUID 00:01:00:01:16:d2:83:fc:92:d4:19:e2:d8:b2
# Note the MAC addresses CANNOT be used to identify DHCPv6 clients.
# Note also that the [] around the IPv6 address are obligatory.
#dhcp-host=id:00:01:00:01:16:d2:83:fc:92:d4:19:e2:d8:b2, fred, [1234::5]

# Ignore any clients which are not specified in dhcp-host lines
# or /etc/ethers. Equivalent to ISC "deny unknown-clients".
# This relies on the special "known" tag which is set when
# a host is matched.
#dhcp-ignore=tag:!known

# Send extra options which are tagged as "red" to any machine whose
# DHCP vendorclass string includes the substring "Linux"
#dhcp-vendorclass=set:red,Linux

# Send extra options which are tagged as "red" to any machine one
# of whose DHCP userclass strings includes the substring "accounts"
#dhcp-userclass=set:red,accounts

# Send extra options which are tagged as "red" to any machine whose
# MAC address matches the pattern.
#dhcp-mac=set:red,00:60:8C:*:*:*

# If this line is uncommented, dnsmasq will read /etc/ethers and act
# on the ethernet-address/IP pairs found there just as if they had
# been given as --dhcp-host options. Useful if you keep
# MAC-address/host mappings there for other purposes.
#read-ethers

# Send options to hosts which ask for a DHCP lease.
# See RFC 2132 for details of available options.
# Common options can be given to dnsmasq by name:
# run "dnsmasq --help dhcp" to get a list.
# Note that all the common settings, such as netmask and
# broadcast address, DNS server and default route, are given
# sane defaults by dnsmasq. You very likely will not need
# any dhcp-options. If you use Windows clients and Samba, there
# are some options which are recommended, they are detailed at the
# end of this section.

# Override the default route supplied by dnsmasq, which assumes the
# router is the same machine as the one running dnsmasq.
#dhcp-option=3,1.2.3.4

# Do the same thing, but using the option name
#dhcp-option=option:router,1.2.3.4
dhcp-option=option:router,192.168.111.1

# Override the default route supplied by dnsmasq and send no default
# route at all. Note that this only works for the options sent by
# default (1, 3, 6, 12, 28) the same line will send a zero-length option
# for all other option numbers.
#dhcp-option=3

# Set the NTP time server addresses to 192.168.0.4 and 10.10.0.5
#dhcp-option=option:ntp-server,192.168.0.4,10.10.0.5

# Send DHCPv6 option. Note [] around IPv6 addresses.
#dhcp-option=option6:dns-server,[1234::77],[1234::88]
dhcp-option=option:dns-server,192.168.111.1

# Send DHCPv6 option for namservers as the machine running
# dnsmasq and another.
#dhcp-option=option6:dns-server,[::],[1234::88]

# Ask client to poll for option changes every six hours. (RFC4242)
#dhcp-option=option6:information-refresh-time,6h

# Set option 58 client renewal time (T1). Defaults to half of the
# lease time if not specified. (RFC2132)
#dhcp-option=option:T1,1m

# Set option 59 rebinding time (T2). Defaults to 7/8 of the
# lease time if not specified. (RFC2132)
#dhcp-option=option:T2,2m

# Set the NTP time server address to be the same machine as
# is running dnsmasq
#dhcp-option=42,0.0.0.0

# Set the NIS domain name to "welly"
#dhcp-option=40,welly

# Set the default time-to-live to 50
#dhcp-option=23,50

# Set the "all subnets are local" flag
#dhcp-option=27,1

# Send the etherboot magic flag and then etherboot options (a string).
#dhcp-option=128,e4:45:74:68:00:00
#dhcp-option=129,NIC=eepro100

# Specify an option which will only be sent to the "red" network
# (see dhcp-range for the declaration of the "red" network)
# Note that the tag: part must precede the option: part.
#dhcp-option = tag:red, option:ntp-server, 192.168.1.1

# The following DHCP options set up dnsmasq in the same way as is specified
# for the ISC dhcpcd in
# http://www.samba.org/samba/ftp/docs/textdocs/DHCP-Server-Configuration.txt
# adapted for a typical dnsmasq installation where the host running
# dnsmasq is also the host running samba.
# you may want to uncomment some or all of them if you use
# Windows clients and Samba.
#dhcp-option=19,0           # option ip-forwarding off
#dhcp-option=44,0.0.0.0     # set netbios-over-TCP/IP nameserver(s) aka WINS server(s)
#dhcp-option=45,0.0.0.0     # netbios datagram distribution server
#dhcp-option=46,8           # netbios node type

# Send an empty WPAD option. This may be REQUIRED to get windows 7 to behave.
#dhcp-option=252,"\n"

# Send RFC-3397 DNS domain search DHCP option. WARNING: Your DHCP client
# probably doesn't support this......
#dhcp-option=option:domain-search,eng.apple.com,marketing.apple.com

# Send RFC-3442 classless static routes (note the netmask encoding)
#dhcp-option=121,192.168.1.0/24,1.2.3.4,10.0.0.0/8,5.6.7.8

# Send vendor-class specific options encapsulated in DHCP option 43.
# The meaning of the options is defined by the vendor-class so
# options are sent only when the client supplied vendor class
# matches the class given here. (A substring match is OK, so "MSFT"
# matches "MSFT" and "MSFT 5.0"). This example sets the
# mtftp address to 0.0.0.0 for PXEClients.
#dhcp-option=vendor:PXEClient,1,0.0.0.0

# Send microsoft-specific option to tell windows to release the DHCP lease
# when it shuts down. Note the "i" flag, to tell dnsmasq to send the
# value as a four-byte integer - that's what microsoft wants. See
# http://technet2.microsoft.com/WindowsServer/en/library/a70f1bb7-d2d4-49f0-96d6-4b7414ecfaae1033.mspx?mfr=true
#dhcp-option=vendor:MSFT,2,1i

# Send the Encapsulated-vendor-class ID needed by some configurations of
# Etherboot to allow is to recognise the DHCP server.
#dhcp-option=vendor:Etherboot,60,"Etherboot"

# Send options to PXELinux. Note that we need to send the options even
# though they don't appear in the parameter request list, so we need
# to use dhcp-option-force here.
# See http://syslinux.zytor.com/pxe.php#special for details.
# Magic number - needed before anything else is recognised
#dhcp-option-force=208,f1:00:74:7e
# Configuration file name
#dhcp-option-force=209,configs/common
# Path prefix
#dhcp-option-force=210,/tftpboot/pxelinux/files/
# Reboot time. (Note 'i' to send 32-bit value)
#dhcp-option-force=211,30i

# Set the boot filename for netboot/PXE. You will only need
# this if you want to boot machines over the network and you will need
# a TFTP server; either dnsmasq's built-in TFTP server or an
# external one. (See below for how to enable the TFTP server.)
#dhcp-boot=pxelinux.0

# The same as above, but use custom tftp-server instead machine running dnsmasq
#dhcp-boot=pxelinux,server.name,192.168.1.100

# Boot for iPXE. The idea is to send two different
# filenames, the first loads iPXE, and the second tells iPXE what to
# load. The dhcp-match sets the ipxe tag for requests from iPXE.
#dhcp-boot=undionly.kpxe
#dhcp-match=set:ipxe,175 # iPXE sends a 175 option.
#dhcp-boot=tag:ipxe,http://boot.ipxe.org/demo/boot.php

# Encapsulated options for iPXE. All the options are
# encapsulated within option 175
#dhcp-option=encap:175, 1, 5b         # priority code
#dhcp-option=encap:175, 176, 1b       # no-proxydhcp
#dhcp-option=encap:175, 177, string   # bus-id
#dhcp-option=encap:175, 189, 1b       # BIOS drive code
#dhcp-option=encap:175, 190, user     # iSCSI username
#dhcp-option=encap:175, 191, pass     # iSCSI password

# Test for the architecture of a netboot client. PXE clients are
# supposed to send their architecture as option 93. (See RFC 4578)
#dhcp-match=peecees, option:client-arch, 0 #x86-32
#dhcp-match=itanics, option:client-arch, 2 #IA64
#dhcp-match=hammers, option:client-arch, 6 #x86-64
#dhcp-match=mactels, option:client-arch, 7 #EFI x86-64

# Do real PXE, rather than just booting a single file, this is an
# alternative to dhcp-boot.
#pxe-prompt="What system shall I netboot?"
# or with timeout before first available action is taken:
#pxe-prompt="Press F8 for menu.", 60

# Available boot services. for PXE.
#pxe-service=x86PC, "Boot from local disk"

# Loads <tftp-root>/pxelinux.0 from dnsmasq TFTP server.
#pxe-service=x86PC, "Install Linux", pxelinux

# Loads <tftp-root>/pxelinux.0 from TFTP server at 1.2.3.4.
# Beware this fails on old PXE ROMS.
#pxe-service=x86PC, "Install Linux", pxelinux, 1.2.3.4

# Use bootserver on network, found my multicast or broadcast.
#pxe-service=x86PC, "Install windows from RIS server", 1

# Use bootserver at a known IP address.
#pxe-service=x86PC, "Install windows from RIS server", 1, 1.2.3.4

# If you have multicast-FTP available,
# information for that can be passed in a similar way using options 1
# to 5. See page 19 of
# http://download.intel.com/design/archives/wfm/downloads/pxespec.pdf


# Enable dnsmasq's built-in TFTP server
#enable-tftp

# Set the root directory for files available via FTP.
#tftp-root=/var/ftpd

# Do not abort if the tftp-root is unavailable
#tftp-no-fail

# Make the TFTP server more secure: with this set, only files owned by
# the user dnsmasq is running as will be send over the net.
#tftp-secure

# This option stops dnsmasq from negotiating a larger blocksize for TFTP
# transfers. It will slow things down, but may rescue some broken TFTP
# clients.
#tftp-no-blocksize

# Set the boot file name only when the "red" tag is set.
#dhcp-boot=tag:red,pxelinux.red-net

# An example of dhcp-boot with an external TFTP server: the name and IP
# address of the server are given after the filename.
# Can fail with old PXE ROMS. Overridden by --pxe-service.
#dhcp-boot=/var/ftpd/pxelinux.0,boothost,192.168.0.3

# If there are multiple external tftp servers having a same name
# (using /etc/hosts) then that name can be specified as the
# tftp_servername (the third option to dhcp-boot) and in that
# case dnsmasq resolves this name and returns the resultant IP
# addresses in round robin fashion. This facility can be used to
# load balance the tftp load among a set of servers.
#dhcp-boot=/var/ftpd/pxelinux.0,boothost,tftp_server_name

# Set the limit on DHCP leases, the default is 150
#dhcp-lease-max=150

# The DHCP server needs somewhere on disk to keep its lease database.
# This defaults to a sane location, but if you want to change it, use
# the line below.
#dhcp-leasefile=/var/lib/misc/dnsmasq.leases

# Set the DHCP server to authoritative mode. In this mode it will barge in
# and take over the lease for any client which broadcasts on the network,
# whether it has a record of the lease or not. This avoids long timeouts
# when a machine wakes up on a new network. DO NOT enable this if there's
# the slightest chance that you might end up accidentally configuring a DHCP
# server for your campus/company accidentally. The ISC server uses
# the same option, and this URL provides more information:
# http://www.isc.org/files/auth.html
#dhcp-authoritative

# Set the DHCP server to enable DHCPv4 Rapid Commit Option per RFC 4039.
# In this mode it will respond to a DHCPDISCOVER message including a Rapid Commit
# option with a DHCPACK including a Rapid Commit option and fully committed address
# and configuration information. This must only be enabled if either the server is
# the only server for the subnet, or multiple servers are present and they each
# commit a binding for all clients.
#dhcp-rapid-commit

# Run an executable when a DHCP lease is created or destroyed.
# The arguments sent to the script are "add" or "del",
# then the MAC address, the IP address and finally the hostname
# if there is one.
#dhcp-script=/bin/echo

# Set the cachesize here.
#cache-size=150

# If you want to disable negative caching, uncomment this.
#no-negcache

# Normally responses which come from /etc/hosts and the DHCP lease
# file have Time-To-Live set as zero, which conventionally means
# do not cache further. If you are happy to trade lower load on the
# server for potentially stale date, you can set a time-to-live (in
# seconds) here.
#local-ttl=

# If you want dnsmasq to detect attempts by Verisign to send queries
# to unregistered .com and .net hosts to its sitefinder service and
# have dnsmasq instead return the correct NXDOMAIN response, uncomment
# this line. You can add similar lines to do the same for other
# registries which have implemented wildcard A records.
#bogus-nxdomain=64.94.110.11

# If you want to fix up DNS results from upstream servers, use the
# alias option. This only works for IPv4.
# This alias makes a result of 1.2.3.4 appear as 5.6.7.8
#alias=1.2.3.4,5.6.7.8
# and this maps 1.2.3.x to 5.6.7.x
#alias=1.2.3.0,5.6.7.0,255.255.255.0
# and this maps 192.168.0.10->192.168.0.40 to 10.0.0.10->10.0.0.40
#alias=192.168.0.10-192.168.0.40,10.0.0.0,255.255.255.0

# Change these lines if you want dnsmasq to serve MX records.

# Return an MX record named "maildomain.com" with target
# servermachine.com and preference 50
#mx-host=maildomain.com,servermachine.com,50

# Set the default target for MX records created using the localmx option.
#mx-target=servermachine.com

# Return an MX record pointing to the mx-target for all local
# machines.
#localmx

# Return an MX record pointing to itself for all local machines.
#selfmx

# Change the following lines if you want dnsmasq to serve SRV
# records.  These are useful if you want to serve ldap requests for
# Active Directory and other windows-originated DNS requests.
# See RFC 2782.
# You may add multiple srv-host lines.
# The fields are <name>,<target>,<port>,<priority>,<weight>
# If the domain part if missing from the name (so that is just has the
# service and protocol sections) then the domain given by the domain=
# config option is used. (Note that expand-hosts does not need to be
# set for this to work.)

# A SRV record sending LDAP for the example.com domain to
# ldapserver.example.com port 389
#srv-host=_ldap._tcp.example.com,ldapserver.example.com,389

# A SRV record sending LDAP for the example.com domain to
# ldapserver.example.com port 389 (using domain=)
#domain=example.com
#srv-host=_ldap._tcp,ldapserver.example.com,389

# Two SRV records for LDAP, each with different priorities
#srv-host=_ldap._tcp.example.com,ldapserver.example.com,389,1
#srv-host=_ldap._tcp.example.com,ldapserver.example.com,389,2

# A SRV record indicating that there is no LDAP server for the domain
# example.com
#srv-host=_ldap._tcp.example.com

# The following line shows how to make dnsmasq serve an arbitrary PTR
# record. This is useful for DNS-SD. (Note that the
# domain-name expansion done for SRV records _does_not
# occur for PTR records.)
#ptr-record=_http._tcp.dns-sd-services,"New Employee Page._http._tcp.dns-sd-services"

# Change the following lines to enable dnsmasq to serve TXT records.
# These are used for things like SPF and zeroconf. (Note that the
# domain-name expansion done for SRV records _does_not
# occur for TXT records.)

#Example SPF.
#txt-record=example.com,"v=spf1 a -all"

#Example zeroconf
#txt-record=_http._tcp.example.com,name=value,paper=A4

# Provide an alias for a "local" DNS name. Note that this _only_ works
# for targets which are names from DHCP or /etc/hosts. Give host
# "bert" another name, bertrand
#cname=bertand,bert

# For debugging purposes, log each DNS query as it passes through
# dnsmasq.
#log-queries

# Log lots of extra information about DHCP transactions.
#log-dhcp

# Include another lot of configuration options.
#conf-file=/etc/dnsmasq.more.conf
#conf-dir=/etc/dnsmasq.d

# Include all the files in a directory except those ending in .bak
#conf-dir=/etc/dnsmasq.d,.bak

# Include all files in a directory which end in .conf
conf-dir=/etc/dnsmasq.d/,*.conf

# If a DHCP client claims that its name is "wpad", ignore that.
# This fixes a security hole. see CERT Vulnerability VU#598349
#dhcp-name-match=set:wpad-ignore,wpad
#dhcp-ignore-names=tag:wpad-ignore
```
