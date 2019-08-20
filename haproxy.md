<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-17 03:03:44
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-17 03:03:44
 -->
# HAProxy

## HAproxy 简介



HAProxy 提供高可用性、负载均衡以及基于TCP和HTTP应用的代理，支持虚拟主机，它是免费、快速并且可靠的一种解决方案。HAProxy 特别适用于那些负载特别大的 web 站点，这些站点通常又需要会话保持和七层处理。HAProxy运行在当前的硬件上，完全可以支持数以万计的并发连接。并且它的运行模式使得它可以很简单安全的整合进您当前的架构中，同时可以保护你的web服务器不被暴露在公网当中。



HAProxy 实现了一种事件驱动，单一进程模型，此模型支持非常大的并发连接数，多进程或多线程模型受内存限制、系统调度器限制以及无处不在的锁限制，很少能处理数千并发连接。事件驱动模型因为在有更好的时间和资源管理的用户端（user-space）实现所有这些任务，所以没有这些问题。此模型的弊端是，在多核系统上，此程序的扩展性通常比较差。这就是为什么他们必须进行优化以使得每个CPU时间片（Cycle）做更多的工作。



## HAProxy 版本

HAProxy 目前主要有两个版本：

### 1.4

>  提供较好的弹性，衍生于 1.2 版本，并提供了额外的新特性，其中大多数是期待已久的。

* 客户端侧的长连接（client-side keep-alive）
* TCP 加速（TCP Speedups）
* 响应池（response buffering）
* RDP 协议
* 基于源的粘性（source-based stickiness）
* 更好的统计数据数据接口（a much better stats interfaces）
* 更详细的健康状态监测机制（more verbose health checks）
* 基于流量的健康评估机制（traffice-based health）
* 支持 http 认证
* 服务器管理命令行接口（server management from the CLI）
* 基于 ACL 的持久性（ACL-based persistence）
* 日志分析器

### 1.3

> 内容交换和超强负载：衍生于 1.2 版本，提供了额外的新特性

* ACL：编写内容交换规则
* 复杂均衡算法（load-balacing algorithms）：更多算法的支持
* 内容探测（connect inspecion）：阻止非授权协议
* 透明代理（transparent proxy）：在Linux 客户端上允许使用客户端IP直接连入服务器
* 内核 TCP 拼接（kernel TCP splicing）：无 copy 方式在客户端和服务端之间转发数据以实现数G级别的数据速率
* 分层设计（layered design）：分别实现套接字、TCP、HTTP处理以提供更好的健壮性、更快的处理机制以及便捷的演进能力
* 快速、公平调度器（fast and fair scheduler）：为某些服务指定优先级可实现理好的QoS
* 会话速率限制（session rate limiting）：适用于托管环境



### 支持的平台及OS

* x86、x86_64、Alpha、SPARC、MIPS及PARISC平台上的 Linux 2.4
* x86、x86_64、ARM（ixp425）以及PPC64平台上的Linux 2.6
* UltraSPARC 2 和 3 上的 Solaris 10
* X86 平台上的 FreeBSD 4.1-8
* i386、amd64、macppc、alpha、sparc64和VAX平台上的 OpenBSD 3.1-current



要获得最高性能，需要在Linux 2.6 或打了 epoll 补丁的 Linux 上运行 haproxy 1.2.5 以上的版本。haproxy 1.11 默认使用的 polling 系统为 `select()`，其处理的文件数达千个时性能便会急剧下降。1.2 和 1.3 版本默认为 `poll()`，在有些操作系统上可能会有性能方面的问题，但在Solaris上表现的相当不错，HAProxy 1.3 在 Linux 2.6 以及打了 epoll 补丁的 Linux 上默认使用 epoll，在 FreeBSD 上使用kqueue，这两种机制在任何负载上都能提供恒定的性能表现。



在较新的版本的 Linux 2.6 (>=2.6.27.19)上，HAProxy 还能够使用 splice() 系统调用在接口间无复制地转发任何数据，这甚至可以达到10GB的性能。



基于以上事实，在 x86 或 x86_64 平台上，要获得最好性能的负载均衡器，建议按照以下顺序参考方案：

* Linux 2.6.32 及以后的版本上运行 HAProxy 1.4
* 打了 epoll 补丁的 Linux 运行 HAProxy 1.4
* FreeBSD 运行 HAProxy 1.4
* Solaris 10 上运行 HAProxy 1.4



## 性能

HAProxy 借助OS上几种常见的技术来实现性能上的最大化

* 单进程、事件驱动模型显著降低了上下文切换的开销及内存占用
* O(1) 事件检查器（event check）允许其在高并发连接中对任何连接的任何事件实现即时探测
* 在任何可用的情况下，单缓冲（single buffering）机制能以不复制任何数据的方式完成读写操作，这会节约大量的CPU时钟周期及内存带宽
* 借助于 Linux 2.6 (>=2.6.27.16) 上的 splice() 系统调用，HAProxy 能实现零复制转发（Zero-copy forwarding），在 Linux 3.5 及以上的 OS 中还可以实现零复制启动（zero-starting）
* MRU 内存分配器在固定大小的内存池中可以实现即时内存分配，这能显著减少创建一个会话的时长
* 树形存储：侧重于使用作者多年前开发的弹性二叉树，实现了以 O(log(N)) 的低开销来保持计时器的命令、保持运行队列命令及管理轮循及最少连接队列
* 优化的 HTTP 首部分析：优化的首部分析功能避免了在 HTTP 首部分析的过程中重读任何内存区域
* 精心的降低了昂贵的系统调用，大部分工作都在用户空间完成，如时间读取、缓冲聚合及文件描述符的启用和禁用等



所有的这些细微之处的优化实现了在中等规模负载之上依然有着相当低的 CPU 负载，甚至在非常高的负载场景中，%5的用户空间占用率和%95的系统空间占用率也是非常普遍的现象，这意味着 HAProxy 进程消耗比系统空间消耗低二十倍以上。因此，对OS进行性能调优是非常重要的。即是用户空间的占用率提高一倍，其CPU占用率也仅为%10，这也解释了为何7层处理对性能影响有限这一现象。由此，在高端系统上HAProxy 的7层性能可以轻易超过硬件负载均衡设备。



在生产环境中，在7层处理上使用  HAProxy 作为昂贵的高端硬件负载均衡设备故障时的紧急解决方案也时长可见。硬件负载均衡设备在“报文”级别处理请求，这在支持跨报文请求（request across multiple packets）有着较高的难度，并且它们不缓冲任何数据，因此有着较长的响应时间，对应地，软件负载均衡设备使用TCP 缓冲，可建立极长的请求，且有着较大的相应时间。



可以从三个因素评估负载均衡器的性能：

1. 会话率
2. 会话并发能力
3. 数据率



## 配置

### 配置文件格式

HAProxy 配置处理3类主要参数来源

1. 最优先处理的命令行参数
2. “global” 配置段，用于设定全局配置参数
3. proxy 相关配置段，如“defaults”，“listen”，“frontend”和“backend”



### 时间格式

一些包含了值的参数表示时间，如超时时长。这些值一般以毫秒为单位，但也可以使用其他时间单位后缀。

* us: 微秒（microseconds），即 1/1000000 秒
* ms: 毫秒（milliseconds），即 1/1000 秒
* s：秒（seconds）
* m：分钟（minutes）
* h：小时（hours）
* d：天（days）



### 实例

下面的例子配置了一个监听在所有接口的80端口上http proxy 服务，它转发所有的请求至后端监听在 `127.0.0.1:8000` 上的 “server”。



```info
global
	daemon
	maxconn 256

defaults
	mode http
	timeout connect 5000ms
	timeout client 50000ms
	timeout server 50000ms

fronrend http-in
	bind *:80
	default-backend servers

backend servers
	server server1 127.0.0.1:8080 maxconn 32
```



### 全局配置

“global” 配置中的参数为进程级别的参数，且通常与其运行的OS相关

* 进程管理及安全相关的参数
  * chroot \<jail dir\> : 修改 haproxy 的工作目录至指定的目录并在放弃权限之前执行 chroot() 操作，可以提升 haproxy 安全级别，不过需要注意的是要确保指定的目录为空目录且任何用户均不能有写权限
  * daemon : 让 haproxy 以进程的方式工作于后台，其等同于“-D”选项的功能，当然，也可以在命令行中以 “-db” 选项将其禁用
  * gid \<number\> : 以指定的GID运行haproxy，建议使用专用于运行 HAProxy 的 GID，以免权限问题带来风险
  * group \<Group Name\> : 同 GID 不过指定的是组名
  * log \<address\> \<facility\> [max level [min level]] : 定义全局的 syslog 服务器，最多可以定义两个
  * Log-send-hostname [\<string\>] :  在 syslog 信息的首部添加当前主机名，可以为 “string” 指定名称，也可以缺省使用当前主机名
  * nbproc \<numbe> : 指定启动的 haproxy 进程个数，只能用与守护进程模式的 HAProxy，默认只启动一个进程，鉴于调试困难等多方面的原因，一般只在单进程仅能打开少数文件描述符的场景中才能使用多进程模式
  * pidfile :
  * uid \<number\> :  以指定的 UID 身份运行 haproxy 进程
  * ulimit-n : 设定每进程能够打开的最大文件描述符数量，默认情况下其会自动进行计算，因此不推荐修改此项
  * user : 同UID，但使用的是用户名
  * stats :
  * node :
  * description : 当前实例的描述信息

* 性能调整先关参数
  * maxconn \<number\> : 设定每个 haproxy 进程所接受的最大并发连接数，其等同于命令行选项`-n` `ulimit -n` 自动计算的结果正是参照此参数设定的
  * maxpipes \<number\> : haproxy 使用 pipe 完成了基于内核的 TCP 报文重组，此选项则用于设定每个进程所允许使用最大的 pipe 个数，每个 pipe 会打开两个文件的描述符。因此，`ulimit -n` 自动计算时会根据需要调大此值；默认为 maxconn/4，其通常会显示的过大。
  *  noepoll : 在 Linux 系统上禁用 epoll 机制
  * nokqueue : 在 BSE 系统上禁用 kqueue 机制
  * nopoll : 禁用 poll 机制
  * nosepoll : 禁止在 Linux 套接字上使用内核 tcp 重组，这会导致更多的 recv/send 系统调用；不过，在 Linux 2.6.25-28 系列的内核上，tcp 重组功能有 bug 存在
  * spread-check \<0-50, in percent\> : 在 haproxy 后端有着众多服务器的场景中，在精确的时间间隔后统一对众服务器进行健康状态检测可能会带来意外问题；此选项用于将其检测的时间间隔长度上增加或减小一定的随机时长
  * tune.bufsize \<number\> : 设定 buffer 的大小，同样的条件内存小，较小的值可以让 haproxy 有能力接收更多的并发连接，较大的值可以让某些应用程序使用较大 cookie 信息，默认为 16384，其可以在编译时修改，不过强烈建议使用默认值。
  * tune.chksize \<number\> : 设定检查缓冲区的大小，单位为字节；更大的值有助于在较大的页面中完成基于字符串或模式的文本查找，但也会占用更多的系统资源；不建议修改
  * tune.maxaccept \<number\> : 设定 haproxy 进程内核调度运行时一次性可以接受的连接的个数，较大的值可以带来较大的吞吐率，默认单进程模式下为 100，多进程模式下为 8，设定为 -1 可以禁止此限制；一般不建议修改
  * tune.maxpollevents \<number\> : 设定一次系统调用可以处理的事件最大数，默认值取决于OS，其值小于 200 时可以节约带宽，但会略微增大网络延迟，而大于 200 时会降低延迟，但会稍稍增加网络带宽的占用量
  * tune.maxrewrite \<number\>: 设定为首部重写或追加而预留的缓冲空间，建议使用1024 左右的大小，在需要使用更大空间的，haproxy 会自动增加其值
  * tune.rcvbuf.client \<number\> :
  * tune.rcvbuf.server \<number\> : 设定内核嵌套字中服务端或客户端接收缓冲的大小，单位为字节；强烈推荐使用默认值
  * tune.sndbuf.client
  * tune.sndbuf.server
* DeBug 相关参数
  * debug
  * quiet



### 代理

代理相关配置可以如下相关配置中

* defaults \<name\>
* frontend \<name\>
* backend \<name\>
* listen \<name\>



`defaults` 段用于为所有其他配置提供默认参数，这配置默认配置参数可由下一个 `defaults` 所重新设定

`frontend` 段用于定义一系列监听的套接字，这些套接字可以接收客户端的请求并与之建立连接

`backend` 段用于定义一系列“后端”服务器，代理将对应客户端的请求转发至这些服务器

`listen` 段通过关联“前端”和“后端”定义了一个完整的代理，通常只对TCP流量有用

所有名称只能使用大写字母、小写字母、数字、`-`（中划线）、`_`（下划线）、`.`（点）和 `:`冒号。此外，ACL名称会区分字母大小写

### 配置文件中的关键字参考

#### balance

```info
balance <algorithm> [<arguments>]
balance url_param <param> [check_post [<max_wait>]]
```



定义负载均衡的算法，可用于 “defaults”、“listen“和“bakcend”。\<algorithm\>

用于在负载均衡场景中挑选一个server，其仅应用于持久信息不可用的条件下或需要将一个连接重新派发至另外一个服务器时。支持的算法有：

* roundrobin : 基于权重进行轮叫，在服务器的处理时间保持均匀分布时，这是最平衡最公平的算法。此算法是动态的，这表示其权重可以在运行时进行调整，不过，在设计上，每个后端服务器最多只能接受4128个连接。
* static-rr : 基于权重进行轮叫，与 roundrobin 类似，但是为静态方法，在运行时调整其服务器权重不会生效；不过，其在后端服务器连接数上没有限制
* leastconn : 新的连接请求被派发至具有最少连接数目的后端服务器：在有着较长回话连接的场景中推荐使用此算法，如 LDAP、SQL等，其并不太适用于较短会话的应用层协议，如 HTTP。此算法是动态的，可以在运行时调整其权重。
* source : 将请求的源地址进行 hash 运算，并由后端服务器的权重总数相除后派发至某匹配的服务器；这可以使得同一个客户端IP的请求始终被派发至某特定的服务器；不过当服务器权重总数发生变化时，如果某服务器宕机或添加了新的服务器，许多客户端的请求可能会被派发至与此前请求不同的服务器；常用于负载均衡无cookie功能的基于TCP的协议；其默认为静态，不过也可以使用 hash-type 修改此特性。
* uri : 对 URI 的有左半部分（“问题”标记之前的部分）或整个 URI 进行 hash 运算，并由服务器的总权重相除后派发至某特定的服务器；这可以使得对同一个URI的请求总是被派发至特定的服务器，除非服务器的权重总数发生了变化；此算法常用于代理缓存或反病毒代理以提高缓存的命中率；需要注意的是，此算法仅用于HTTP后端服务器场景；其默认为静态算法，不过也可以使用 hash-type 修改此特性。
* url_param :  通过 \<argument\> 为URL指定的参数在每个 HTTP GET 请求中将会被检索：如果找到了指定的参数且其通过等于号`=`被赋予了一个值，那么此值将被执行 hash 运算并被服务器的总权重相除后派发至某匹配的服务器；此算法可以通过追踪请求中的用户标识进而确保同一个用户ID的请求将被发往同一个特定的服务器，除非服务器的总权重发生了变化；如果某请求中没有出现指定的参数或其没有有效值，则使用轮叫算法对相应请求进行调度；此算法默认为静态的，不过其可以使用 hash-type 修改此特性；
* hdr\<name\>) : 对于每个 HTTP 请求，通过 \<name\> 指定的HTTP首部将会被检索：如果相应的首部没有出现或其没有有效值，则使用轮叫算法对相应请求进行调度；其有一个可选选项 `use_daemon_only` ，可以在指定检索类似 host 类的首部时仅计算域名部分（比如通过 www.baidu.com 来说，仅计算 baidu 字符串的 hash 值）以降低 hash 算法的计算量；此算法默认是静态的，不过其也可以使用 hash-type 修改此特性
* rdp-cookie
* rdp-cookie(name) :

#### bind

```info
bind [<address>]:<port_range> [,...]
bind [<address>]:<port_range> [,...] interface <interface>
```

此指令仅能用于`frontend`和`listen`区段，用于定义一个或几个监听的套接字。

* \<address\> : 可选选项，其可以为主机名、IPv4 地址、IPv6 地址或 *；省略此选项、将其指定为 * 或 0.0.0.0 时，将监听当前系统所有 IPv4 地址；
* \<port_range\> : 可以是一个特定的TCP端口，也可以是一个端口范围（如5005-5010），代理服务器将通过指定的端口来接收客户端的请求；需要注意的是，每组监听的套接字 \<address:port\> 在同一个实例上只能使用一次，而且小于 1024 的端口需要有特定权限的用户才能使用，这可能需要通过 uid 参数来定义；
* \<interface\> : 指定物理接口的名称，仅能在Liunx 系统上使用；其不能使用接口别名，而仅能使用物理接口名称，而且只有管理有权限指定绑定的物理接口



#### mode

```info
mode {tcp|http|health}
```

设定实例的运行模式或协议。当实现内容交换时，前端和后端必须工作于同一种模式（一般来说都是 HTTP 模式），否则将无法启动实例。

* tcp : 实例运行于纯 TCP 模式，在客户端和服务端之间将建立一个全双工的连接，且不会对7层报文做任何类型的检查；此为默认模式，通常用于 SSL、SSH、SMTP 等应用
* http : 实例运行于 HTTP 模式，客户端请求在转发至后端服务器之前将被深度分析，所有不与RFC格式兼容的请求都会被拒绝；
* health : 实例工作于 health 模式，其对入站请求仅响应”ok“信息并关闭连接，且不会记录任何日志信息；此模式将用于响应外部组件的健康状态检查请求；目前来讲，此模式已经废弃，因为tcp和http模式中的 monitor 关键字可以完成类似的功能



#### hash-type

```info
hash-type <method>
```

定义用于将 hash 码映射至后端服务器的方法：其不能用于frontend区段；可用的方法有 map-based 和 consistent，在大多数场景下推荐使用默认的 map-based 方法。

* map-based : hash 表是一个包含了所有在线服务器的静态数组，其 hash 值将会非常的平滑，会将权重考虑在列，但其为静态方法，对在线服务器的权重进行调整将不会生效，这意为这其不支持慢速启动。此外，挑选服务器是根据其在数组中的位置进行的，因此，当一台服务器宕机或添加了一台新的服务器时，大多数连接将会被重新派发至一个与此前不通的服务器上，对于缓存服务器的工作场景来说，此方法不甚使用。
* consistent : hash 表是一个由各服务器填充而成的树状结构：基于 hash 键在 hash 树中查找相应的服务器时，最近的服务器将被选中，此方法是动态的，支持在运行时修改服务器权重，因此兼容慢速启动的特性，添加一个新的服务器时，仅会对一小部分请求产生影响，因此，由其适用于后端服务器为 cache 场景，不过，此算法不甚平滑，派发至各服务器的请求未必能达到理想的理想的均衡效果，因此，可能需要不时的调整服务器的权重以获得更好的均衡性。



#### log

```info
log global
log <address> <facility> [<level> [<minlevel>]]
```

为每个实例启用时间和流量日志，因此可用于所有区段，每个实例最多可以指定两个 log 参数，不过，如果使用了 `log global` 且`global` 段已经定了 log 参数时，多余的 log 参数将被忽略。

* global : 当前实例的日志系统参数同 `global` 段中的定义时，将使用此格式；每个实例仅能定义一次 `log global` 语句，且其没有任何额外的参数。
* \<address\> : 定义日志发往的位置，其格式之一可以为 \<IPv4_address:PORT\>，其中的port为 UDP 协议的端口，默认为 514：格式之二为Unix套接字文件路径，但需要留心 chroot 应用及用户的读写权限。
* \<facility\> : 可以为 syslog 系统的标准 facility 之一。
* \<level\> : 定义日志级别，即输出信息过滤器，默认为所有信息；指定级别是，所有等于或高于此级别的日志信息将被发送

#### maxconn

```
maxconn <conns>
```

设定一个前端的最大并发连接数，因此，其不能用于 backend 区段，对于大型站点来说，可以尽可能提高此值以便让 haproxy 管理链接队列，从而避免无法应答用户请求，当然，此最大值不能超出 `global` 段中的定义。此外，需要留心的是，haproxy 会为每个链接维持两个缓冲，每个缓冲的大小为 8 KB，再加上其他的数据，每个连接将大约占用 17 KB 的 RAM 空间。这意味着经过适当优化后，有着 1GB 的可用 RAM 空间时将能能为 40000-50000 并发连接。

如果为 \<conns\> 指定了一个过大值，极端场景下，其最终占据的空间可能会超出当前主机的可用内存，这可能会带来意想不到的结果；因此，将其设定了一个可以接受的值方为明智之选，其默认为 2000



#### default_backend

```info
default_backend <backend>
```

在没有匹配的 `use backend` 规则时为实例指定使用的默认后端，因此，其不可应用于 backend 区段，在 `frontend` 和 `backend` 之间进行内容交换时，通常使用 `use-backend` 定义其匹配规则；而没有被规则匹配到的请求将由此参数指定的后端接收。

* \<backend\> : 指定使用的后端的名称

```info
use_backend	dynamic if	url_dyn
use_backend	static	if url_css url_img extension_img
default_backend	dynamic
```



#### server

```info
server <name> <address>[:port] [param*]
```

为后端声明一个 server，因此，不能用于 defaults 和 frontend 区段

* \<name\> : 为此服务器指定的内部名称，其将出现在日志即警告信息中；如果设定了 `http-send-server-name`，它还将被添加至发往此服务器的请求首部中；
* \<address\> : 此服务器的 IPv4 地址，也支持使用可解析的主机名，只不过在启动时需要解析主机名至相应的IPv4地址；
* \[:port\] : 指定将连接请求所发往的此服务器的目标端口，其为可选项；未设定时，将使用客户端请求时的同一相同端口
* \[param*\] : 为此服务器设定的一系列参数：其可用的参数非常多，具体请参考官方文档中的说明，下面仅说明几个常用的参数：



服务器或默认服务器参数：

* backup : 设定为备用服务器，仅在负载均衡场景中的其他 server 均不可用于启用此 server;
* check : 启动对此 server 执行健康状态检查，其可以借助于额外的其他参数完成更精细的设定，如：
  * Inter \<delay\> : 设定健康状态检查的时间间隔，单位为毫秒，默认为 2000；也可以使用 fastinter 和 downinter 来根据服务器状态优化此时间延迟；
  * rise \<count\> : 设定健康状态检查中，某离线的 server 从离线状态转换至正常状态需要成功检查的次数；
  * fall \<count\> : 确认 server 从正常状态转换为不可用状态需要检查的次数；
* cookie \<value\> : 为指定 server 设定 cookie 值，此处指定的值将在请求入站时被检查，第一次为此值挑选的 server 将在后续的请求中被选中，其目的在于实现持久连接的功能；
* maxconn \<maxconn\> : 指定此服务器接受的最大连接数：如果发往此服务器的连接数目高于此处指定的值，其将被放置于请求队列，以等待其他连接被释放
* maxqueue \<maxqueue\> : 设定请求队列的最大长度
* observe \<mode\> : 通过观察服务器的通信状况来判断健康状态，默认为禁用，其支持的类型有 `layer4` 和 `layer7` , `layer7` 仅能用于 http 代理场景
* redir \<prefix\> : 启用重定向功能，将发往此服务器的 GET 和 HEAD 请求均以 302 状态码相应；需要注意的是，在 prefix 后面不能使用 `/`，且不能使用相对地址，以免造成循环：例如 `server srv1 172.16.100.6:80 redir http://imageserver.renkeju.com check`
* weight \<weight\> : 权重，默认为1，最大值为 256，0 表示不参与负载均衡



检查方法：

```info
option httpchk
option httpchk <uri>
option httpchk <method> <uri>
option httpchk <method> <uri> <version> # 不能用于 frontend 段
```

例如：

```info
backend htto_relay
	mode tcp
	option httpchk OPTION * HTTP/1.1\r\nHost:\ www
	server apache1 192.168.1.1:443 check port 80
```

使用案例：

```info
server first	172.16.100.7:1080 cookie first check inter 1080
server second	172.16.100.8:1080 cookie second check inter 1080
```



#### capture request header

```info
capture request header <name> len <length>
```

捕获并记录指定的请求首部最近一次出现时的第一个值，仅能用于`frontend` 和 `listen` 区段，捕获的首部值使用花括号 `{}`  括起来后添加进日志中，如果需要捕获多个首部值，它们将以指定的次序出现在日志文件中，并以竖线`|` 作为分隔符。不存在的首部记录为空字符串，最常需要捕获的首部包括在虚拟主机环境中使用的 `Host`、上传请求首部中的 `Content-length`、快速区别真实用户和网络机器人的 `User-agent`，以及代理环境好中记录真实请求来源的 `X-Forward-For`。

* \<name\> : 要捕获的首部的名称，此名称不区分字符大小写，但建议与他们出现在首部中的格式相同，比如大写首字母，需要注意的是，记录在日志中的首部对应的值，而非首部的名称。
* \<length\> : 指定记录首部值所记录的精确长度，超出的部分将会被忽略。

可以捕获的请求首部的个数没有限制，但每个捕获最多只能记录64个字符。为了保证同一个 frontend 中日志格式的统一性，首部捕获仅能在 frontend 中定义。



#### capture response header

```info
capture response header <name> len <length>
```

捕获并记录相应首部，其格式和要点同请求首部。



#### stats enable

启用基于程序编译时默认设置的统计报告，不能用于`frontend` 区段，只要没有另外的其他的设定，他们就会使用如下的配置：

* stats uri	: /haproxyadmin?stats
* stats realm : "HAProxy Statistics"
* stats auth  : no authentication
* stats scope : no restriction

尽管 `stats enable` 一条就能够启用统计报告，但还是建议设定其他所有的参数，以免其依赖于 默认设定而带来的非预期后果，下面是一个配置案例。

```info
backend public_www
	server websrv1 172.16.100.11:80
	stats enable
	stats hide-version
	stats scope
	stats uri	/haproxyadmin?stats
	stats realm	haproxy\ Statistics
	stats auth	statsadmin:password
	stats auth  statsmaster:password
```

#### stats hide-version

```info
stats hide-version
```

启用统计报告并隐藏 HAProxy 版本报告，不能用于 `frontend` 区段。默认情况下，统计页面会显示一些有用信息，包括 HAProxy 的版本号，然而，向所有人公开 HAProxy 的精确版本号是非常有风险的，因为他能帮助恶意用户快速定位版本的缺陷和漏洞，尽管`stats hide-version` 一条就能够启用统计报告，但还是建议设定其他所有的参数，以免其依赖于默认设定而带来的非期后果。具体请参照"stats enable" 一节的说明。



#### stats realm

```info
stats realm <realm>
```

启用统计报告并高精认证领域，不能用于 `frontend` 区段，haproxy 在读取 realm 时会将其视作一个单词，因此，中间的任何空白字符都必须使用反斜线进行转义。此参数仅在与 `stats auth` 配置使用时有意义。

* \<realm\> ：实现 HTTP 基本认证时显示在浏览器中的领域名称，用于提示用户输入一个用户名和密码

尽管 `stats realm` 一条就能够启用统计报告，但是还建议设定其他所有的参数，以免其依赖于默认设定而带来的非期后果。具体请参照`stats enable` 一节的说明。



#### stats scope

```info
stats scope { <name> | "." }
```

启用统计报告并限定报告的区段，不能用于 `frontend` 区段，当之低昂此语句时，统计报告将仅显示其列举出区段的报告信息，所有其他区段的信息将被隐藏，如果需要显示多个区段的统计报告，此语句可以定义多次，需要注意的是，区段名称检测仅仅是以字符串比较的方式运行，它不会真检测指定的区段是否真正存在。

* \<name\> : 可以是一个“listen”、“frontend“ 或 ”backend“区段的名称，而 ”.“ 则表示 stats scope 语句所定义的当前区段。

尽管 `stats scope` 一条就能够启用统计报告，但还是建议设定其他所有的参数，以免其依赖于默认设定而带来非期后果，下面试一个配置案例。

```info
backend private_monitoring
	stats enable
	stats uri	/haproxyadmin?stats
	stats refresh 10s
```

#### stats auth

```info
stats auth <user>:<password>
```

启用带认证的统计报告功能逼格授权一个用户账号，其不能用于`frontend`区段

* \<user\> : 授权进行访问的用户名
* \<stats\> ：此用户的访问密码： 明文格式

此语句将基于默认设定启用统计报告功能，并仅允许其定义的用户访问，其也可以定义多次以授权多个用户账号，可以结合`stats realm` 参数在提示用户认证时给出一个领域说明信息，在使用非法用户访问统计功能时，其将会相应一个 `401 Forbidden`  页面，其认证方式为 HTTP Basic 认证，密码传输会以明文方式进行，因此，配置文件中也使用明文方式存储以说明其非保密信息故此不能相同于其他关键性账号的密码。

尽管 `stats auth` 一条就能够启用统计报告，但还是建议设定其他所有的参数，以免其依赖于默认设定而带来的非期后果。



#### stats admin

```info
stats admin { if | unless } <cond>
```

 在指定的条件满足是启用统计报告页面的管理级别功能，它允许通过 web 接口启用或禁用服务器，不过，基于安全角度考虑，统计报告页面应尽可能为只读的。此外，如果启用了HAProxy 的多进程模式，启用此管理级别将有可能导致异常行为。

目前来说，POST请求方法被限制于仅能使用缓冲区减去保留部分之外的空间，因此，服务器列表不能过长，否则，此请求将无法正常工作，因此，建议一次仅调整少数几个服务器，下面是两个案例，第一个限制了仅能在本机打开打开报告页面是启用管理级别功能，第二个定义了仅允许通过认证的用户使用管理级别功能。

```info
backend stats_localhost
	stats enable
	stats admin if LOCALHOST

backend stats_auth
	stats enable
	stats auth haproxyadmin:password
	stats admin if TRUE
```



#### option httplog

```info
option httplog [ clf ]
```

启用记录 HTTP 请求、会话状态和计时器的功能

clf : 使用CLF  格式来代替 HAProxy 默认的 HTTP 格式，通常在使用仅支持 CLF 格式的特定日志分析器时才需要使用此格式。

默认情况下，日志输入格式非常简陋，因为其仅包括源地址、目标地址和实例名称，而 `option httplog` 参数将会使得日志格式变得丰富许多，其通常包括但不限于 HTTP 请求、连接计时器、会话状态、连接数、捕获的首部及 cookie、`frontend`和`backend` 及服务器名称，当然也包括源地址和端口号等。

#### option logasap

```info
option logasap
no option logasap
```

启用或禁用提前将 HTTP 请求记入日志，不能用于 `backend` 区段。

默认情况下，HTTP 请求是在请求结束时进行记录以便能将其整体传输时长和字节数记入日志，由此，传输较大的对象时，其记入日志的时长可能会略有延迟。`option logasap` 参数能够在服务器发送 complete 首部时即时记录日志，只不过，此时将不记录整体传输时长和字节数。此情景下，捕获 `Content-Length` 相应首部来记录传输的字节数是一个较好选择，下面是一个例子：

```info
listen http_proxy 0.0.0.0:80
	mode http
	option httplog
	option logasap
	log 172.16.100.9 local2
```

 #### option forwardfor

```info
option forwardfor [ except <network> ] [ header <name> ] [ if-none ]
```

允许在发往服务器的请求首部中插入 `X-Forwarded-For` 首部

* \<network\> : 可选参数，当指定是，源地址为匹配至此网络中的请求都禁用功能

* \<name\> : 可选参数，可使用一个自定义的首部，如 `X-Forwarded-For`，有些独特的 web 服务器的确需要用于一个独特的首部。

* if-none : 仅在此首部不存在时才将其添加至请求报文中



Haproxy 工作于反向代理模式，其发往服务器的请求中的客户端IP均为HAProxy主机的地址而非真正客户端的地址，这会使得服务器端的日志信息记录不了真正的请求来源，`X-Forwarded-For`首部则可用于解决此问题，HAProxy 可以向每个发往服务器的请求上添加此首部，并以客户端IP为其value。

需要注意的是，HAProxy工作与隧道模式，其仅检查每一个连接的第一个请求，因此，仅第一个请求报文被附加此首部，如果想为每一个请求都附加此首部，请确保同时使用了 `option httpclose`、`option forceclose`和`option http-server-close`几个 option。

下面是一个例子：

```info
frontend www
	mode http
	option forwarded except 127.0.0.1
```



#### errorfile

```info
errorfile <code> <file>
```

 在用户请求不存在的页面时，返回一个页面文件给客户端而非由haproxy生成的错误代码：可用于所有段中。

* \<code\> : 指定对 HTTP 的那些状态码返回指定的页面：这里可用的状态码有 200、400、403、408、500、502、503 和 504。
* \<file\> : 指定用于相应的页面文件



例如：

```info
errorfile 400 /etc/haproxy/errorpages/400badreg.http
errorfile 403 /etc/haproxy/errorpages/403badreg.http
errorfile 503 /etc/haproxy/errorpages/503badreg.http
```

#### errorloc 和 errorloc302

```info
errorloc <code> <url>
errorloc302 <code> <url>
```

请求错误时，返回一个HTTP重定向至某URL的信息：可用于所有配置段中。

* \<code\> : 指定对 HTTP 的哪些状态码返回指定的页面；这里可用的状态码有 200、400、403、408、500、502、503 和 504。
* \<url\> : Location 首部中指定的页面位置的具体路径，可以是在当前服务器上的页面的相对路径，也可以使用绝对路径：需要注意的是，如果URI自身错误是产生某特定状态码信息的话，有可能会导致循环定向。

需要留意的是，这两个关键字都会返回 302 状态码，这将使得客户端使用同样的HTTP方法获取指定的URL，对于非GET方法的场景（如POST）来说会产生问题，因为返回客户的URL是不允许使用GET以外的其他方法的。如果的确有这种问题，可以使用 errorloc303 来返回 303 状态码给客户端。

#### errorloc303

```info
errorloc303 <code> <url>
```

请求错误时，返回一个 HTTP 重定向至某 URL 的信息给客户端：可用于所有配置段中。

* \<code\> : 指定对HTTP的哪些状态码返回指定的页面：这里可用的状态码有 400、403、408、500、502 和 504
* \<url\> : Location 首部中指定的页面位置的具体路径，可以是在当前服务器上页面的绝对路径；也可以使用绝对路径；需要注意的是，如果URI自身错误时产生某特定状态码信息的话，有可能会导致循环定向。

例如：

```info
backend webserver
	server 172.16.100.6 172.16.100.6:80 check maxconn 3000 cookie srv01
	server 172.16.100.7 172.16.100.7:80 check maxconn 3000 cookie srv02
	errorloc 403 /etc/haproxy/errorpages/sorry.htm
	errorloc 503 /etc/haproxy/errorpages/sorry.htm
```



## 配置实例

```ini
#----------------------------------------------------
# Global settings
#----------------------------------------------------
global
	# to have these messages end up in /var/log/haproxy.log you will
	# need to:
	#
	# 1) configure syslog to accept network log events. This is done
	# 	 by adding the '-r' option to the SYSLOGD_OPTIONS in
	#	 /etc/sysconfig/syslog
	# 2) configure local2 events to go to the /var/log/haproxy.log
	#   file. A line like the following can be added to
	#   /etc/sysconfig/syslog
	#
	#   local2.*		/var/log/haproxy.log
	log		127.0.0.1	local2

	chroot 		/var/lib/haproxy
	pidfile		/var/run/haproxy.pid
	maxconn		4000
	user		haproxy
	group		haproxy
	daemon

defaults
	mode		http
	log			global
	option		httplog
	option		dontlognull
	option		http-server-close
	option		forwardfor
	option		except	127.0.0.0/8
	option		redispatch
	retries		3
    timeout	http-request	10s
    timeout	queue			1m
    timeout	connect			10s
    timeout client			1m
    timeout	server			1m
    timeout	http-keep-alive	10s
    timeout check			10s
    maxconn					30000

listen	stats
	mode	http
	bind	0.0.0.0:1080
	stats	enable
	stats	hide-version
	stats	uri	/haproxyadmin?stats
	stats	realm	Haproxy\ Statistics
	stats	auth	admin:password
	stats	admin if TRUE

frontend http-in
	bind	*:80
	mode	http
	log		global
	option	httpclose
	option	logasap
	option	dontlognull
	capture	request	header	Host len 20
	capture	request	header	Referer	len 60
	default_backend	servers

frontend healthcheck
	bind :1099
	mode http
	option  httpclose
	option	forwardfor
	default_backend	servers

backend servers
	balance roundrobin
	server websrv1	192.168.10.11:80 check maxconn 2000
	server websrv2  192.168.10.12:80 check maxconn 2000
```



## RabbitMQ 配置实例

```ini
global
	log 127.0.0.1 local0 info
	maxconn 4096
	chroot /var/lib/haproxy
	user haproxy
	group haproxy
	daemon
	pidfile /var/run/haproxy.pid

defaults
	log global
	mode tcp
	option tcplog
	option dontlognull
	retries	3
	maxconn 2000
	timeout connect 5s
	timeout client 120s
	timeout server 120s

listen rabbitmq_cluster :5671
	mode tcp
	balance roundrobin
	server rmq_node1 172.16.0.9:5672 check inter 5000 rise 2 fall 3 weight 1
	server rmq_node2 172.16.0.8:5672 check inter 5000 rise 2 fall 3 weight 1
	server rmq_node1 172.16.0.6:5672 check inter 5000 rise 2 fall 3 weight 1

listen monitor :8100
	mode http
	option httplog
	stats enable
	stats uri /stats
	stats refresh 5s
```

