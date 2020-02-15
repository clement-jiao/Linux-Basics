### 时间同步

#### 时间同步工具
在CentOS6中，默认是使用ntpd来同步时间的，但ntpd同步时间并不理想，有可能需要数小时来同步时间，所以在Centos7中换成了chrony来实现时间同步。
chrony并且兼容ntpd监听在udp123端口上，自己则监听在udp的323端口上。

#### Chrony
如果在chrony配置文件中指定了ntp服务器的地址，那么chrony就是一台客户端，会去同步ntp服务器的时间，如果在chrony配置了允许某些客户端来向自己同步时间，则chrony也充当了一台服务器，所以，安装了chrony即可充当客户端也可以充当服务端。

#### 程序环境：
```
配置文件：/etc/chrony.conf
主程序文件：chronyd #一个守护daemon程序
工具程序：chronyc   #一个交互式命令行工具
unit file: chronyd.service
```

#### 配置文件：chrony.conf
```
server：指明时间服务器地址；
allow NETADD/NETMASK
allow all：允许所有客户端主机；
deny NETADDR/NETMASK
deny all：拒绝所有客户端；
bindcmdaddress：命令管理接口监听的地址；
local stratum 10：即使自己未能通过网络时间服务器同步到时间，也允许将本地时间作为标准时间授时给其它客户端；
```

#### chrony的交互工具chronyc
chrony自带一个交互式工具chronyc，在配置文件中指定了时间服务器之后，如果想查看同步状态，可以进入这个交互式工具的交互界面。

```
chronyc有很多的子命令，可以输入help来查看
chronyc> help
    选项：
    sources [-v]    显示关于当前来源的信息
    sourcestats [-v]      显示时间同步状态（如时间偏移了多少之类）

================================例如：====================================
chronyc> sources -v
210 Number of sources = 1

  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current synced, '+' = combined , '-' = not combined,
| /   '?' = unreachable, 'x' = time may be in error, '~' = time too variable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* 203.107.6.88                  2  10   104   64m  +1485us[ +417us] +/-   81ms


================================重点关注此行====================================
#主要关注第一列的MS，
^*  ^是指该行所给出的IP是服务器，也就是我们指定的互联网时间服务器；*是指当前已同步
===============================================================================


###############################################################################
chronyc>
chronyc> sourcestats -v #sourcestats是显示同步状态，-v是详细西信息
210 Number of sources = 1
                             .- Number of sample points in measurement set.
                            /    .- Number of residual runs with same sign.
                           |    /    .- Length of measurement set (time).
                           |   |    /      .- Est. clock freq error (ppm).
                           |   |   |      /           .- Est. error in freq.
                           |   |   |     |           /         .- Est. offset.
                           |   |   |     |          |          |   On the -.
                           |   |   |     |          |          |   samples. \
                           |   |   |     |          |          |             |
Name/IP Address            NP  NR  Span  Frequency  Freq Skew  Offset  Std Dev
==============================================================================
203.107.6.88               29  18   18h     -0.003      0.132    -14us  5055us
```
