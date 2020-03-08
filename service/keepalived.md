<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-20 02:38:46
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-20 15:22:52
 -->
#centOS 7 下 keepalived 安装与配置

##keepalived 与 lvs 之间关系
  - LVS
    >全称Linux Virtual Server，也就是Linux虚拟服务器，由章文嵩（现就职于于淘宝，正因为如此才出现了后来的fullnat模式）博士发起的Load  Balance开源项目，官网地址：[www.linuxvirtualserver.org](www.linuxvirtualserver.org)

  - keepalived
    > keepalived是Linux下一个轻量级别的高可用解决方案。高可用（High Avalilability，HA），广义上讲，是指整个系统的高可用行，狭义上来说就是主机的冗余和接管；
      为什么是轻量级呢，keepalived 通过 VRRP（Vritrual Router Redundancy Protocol：虚拟路由冗余协议）实现网络不间断稳定运行；与HeartBeat RoseHA相比，
      HeartBeat 提供了完整的HA基本功能，比如：心跳检测，资源接管，检测集群中的服务，在集群节点转移共享ip地址所有者等等；
      虽然功能强大，但是部署使用相对麻烦，而 keepalived 只需一个配置文件就可搞定。

  - LVS 与 keepalived 的关系：类似于 nginx&php 或 apache&php
    > keepalived 起初是为 LVS 设计的，由于 Keepalived 可以实现对集群节点的状态检测，而 LVS 可以实现负载均衡功能。因此，keepalived 借助于第三方模块 IPVS/LVS 就可以很方便的搭建出一套负载均衡系统；

    ```bash
    # 在这里有个误区，由于 keepalived 可以和 IPVS 一起很好的工作，
    # 很多朋友以为 Keepalived 就是一款负载均衡软件，这种理解是错误的，他们是互补的，
    # keepalived 是可以直接操作配置 LVS 的！
    ```
    >在 keepalived 当中 IPVS 模块是可配置的，如果需要负载均衡功能，可以在编译 keepalived 时打开负载均衡功能，也可以通过编译参数关闭。
  - haproxy
    >HAProxy提供高可用性、负载均衡以及基于TCP和HTTP应用的代理，支持虚拟主机，它是免费、快速并且可靠的一种解决方案。HAProxy特别适用于那些负载特大的web站点，这些站点通常又需要会话保持或七层处理。HAProxy运行在当前的硬件上，完全可以支持数以万计的并发连接。并且它的运行模式使得它可以很简单安全的整合进您当前的架构中， 同时可以保护你的web服务器不被暴露到网络上。
    HAProxy实现了一种事件驱动, 单一进程模型，此模型支持非常大的并发连接数。多进程或多线程模型受内存限制 、系统调度器限制以及无处不在的锁限制，很少能处理数千并发连接。事件驱动模型因为在有更好的资源和时间管理的用户空间(User-Space) 实现所有这些任务，所以没有这些问题。此模型的弊端是，在多核系统上，这些程序通常扩展性较差。这就是为什么他们必须进行优化 使每个CPU时间片(Cycle) 做更多的工作。
  - LVS 与 haproxy
    > LVS只工作在4层，没有流量产生，使用范围广，对操作员的网络素质要求较高；
    HAproxy及支持7层也支持4层的负载均衡，更专业；
    推荐模式：F5/LVS <—> Haproxy <—> Squid/Varnish <—> AppServer

##安装依赖项
  - 安装 keepalived 编译依赖和 LVS
    ```bash
    yum install -y gcc openssl-devel \
    libnl libnl-devel libnfnetlink-devel \
    net-tools ipvsadm iptables-services \
    ipvsadm
    ```

##安装keepalived
  - 由于 yum 源版本过旧(1.5)，所以在官网下载源码包(2.0.13)自己构建并编译
    ```bash
    mkdir -p /opt/install/keepalived
    cd /opt/install/keepalived
    wget http://www.keepalived.org/software/keepalived-2.0.13.tar.gz
    tar zxvf keepalived-2.0.13.tar.gz
    cd keepalived-2.0.13

    ./configure --prefix=/usr/local/keepalived/

    make && make install
    ```

  - 配置自动启动
    ```bash
    mkdir /etc/keepalived
    cp /usr/local/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf
    cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig/keepalived
    ```


##配置keepalived
  - 注意：需要注释 #vrrp_strict，否则将会发生无法向 VIP ping通的问题，包括无法访问页面。
    ```bash
    ! Configuration File for keepalived
    global_defs {
      router_id haproxy_nginx1
      vrrp_skip_check_adv_addr
      #vrrp_strict
      vrrp_garp_interval 0
      vrrp_gna_interval 0
      }
    # vrrp_script check_local {
    #     script "/etc/keepalived/chk_haproxy.sh 192.168.0.163 200"
    #     interval 5      # 运行间隔
    #     weight -20      # 降权级别：降权后需要小于 BACKUP
    #     fall 2          # 连续失败两次进行降权
    #     rise 3          # 连续成功三次恢复权限
    #     user keepalived # 运行脚本用户
    # }
    # 在 check_local 定义的检测规则为：
    # 1. 自身web服务故障（超时，http返回状态不是200）
    # 2.  无法ping通网关
    # 3.  产生以上任何一个问题，均应该移除本机的虚拟IP(停止keepalived实例即可)
    vrrp_instance VI_1 {
      state MASTER          # 指定A节点为主节点 备用节点上设置为BACKUP即可
      interface ens192      # 绑定虚拟IP的网络接口:ip ad 可以查看
      virtual_router_id 51
      priority 100          # 主节点的优先级（1-254之间），备用节点必须比主节点优先级低,优先级数字越大优先级越高。
      advert_int 1          # 组播信息发送间隔，两个节点设置必须一样
      authentication {      # 设置vrrp验证信息，两个节点必须一致
        auth_type PASS      # 设置验证类型，主要有PASS和AH两种
        auth_pass 1111      # 设置验证密码，在同一个vrrp_instance下，MASTER与BACKUP必须使用相同的密码才能正常通信
        }
        virtual_ipaddress {
          192.168.0.233/24  # 设置虚拟IP地址，可以设置多个虚拟IP地址，每行一个
          }
        track_script {      # 检查自身状态脚本
          check_local
        }
      }
    virtual_server 192.168.0.233 80 {     # 虚拟服务器端口配置
      delay_loop 6
      lb_algo rr
      lb_kind DR
      #persistence_timeout 50
      protocol TCP
      real_server 192.168.0.163 80 {
        weight 1
        TCP_CHECK {
          connect_timeout 5
          retry 2
          delay_before_retry 3
          connect_port 80
          }
        }
      real_server 192.168.0.111 80 {
        weight 1
        TCP_CHECK {
          connect_timeout 5
          retry 2
          delay_before_retry 3
          connect_port 80
          }
        }
      }
    ```
    >在配置文件中没有写VIP的子网掩码，会使用默认子网掩码255.255.255.255，有可能导致无法从其它机器访问虚拟IP（keepalived虚拟IP无法ping通）所以尽量指定子网掩码/24即可。
  - 配置 BACKUP 服务器时注意以下几点：
    1. state 角色为 BACKUP
    2. interface 为网卡的 ID，要根据机器确认
    3. virtual_route_id 要与 MASTER 一致，默认为 51
    4. priority 要比 MASTER 小
    5. unicast_src_ip 要设置正确，组播地址设置之后，要注释 vrrp_strict 选项

  - 状态检测脚本
    ```bash
    #!/usr/bin/env bash

    check_ip=$1
    check_http_status_code=$2
    code=$(curl -Is http://${check_ip} | grep -c ${check_http_status_code})
    if [[ ${code} -ne 1 ]]
    then
        exit 1
    fi
    ```
    >关于 check_local 脚本的一个小问题，如果本机或是网关偶尔出现一次故障，那么我们不能认为是服务故障。更好的做法是如果连续 N 次检测本机服务不正常或连接 N 次无法 ping 通网关，才认为是故障产生，才需要进行故障转移。另一方面，如果脚本检测到故障产生，并停止掉了 keepalived 服务，那么当故障恢复后， keepalived 是无法自动恢复的。我觉得利用独立的脚本以秒级的间隔检查自身服务及网关连接性，再根据故障情况控制 keepalived 的运行或是停止。

##启动keepalived并启用自动启动
  - 开机自启并启动服务
    ```bash
    systemctl enable keepalived.servic
    systemctl start keepalived.service
    systemctl status keepalived.service
    ```


##常见问题
  - 无法绑定TCP
    >下载源码包编译安装。
  - 不能ping
    >请在 vim /etc/keepalived/keepalived.conf 中注释 vrrp_strict
  - 无法转发入站请求
    请检查你的真实服务器的应用程序是否绑定到0.0.0.0 或 IPV6上
    或者是否开启了 数据表转发功能：
    ```conf
    # vim /etc/sysctl.conf
    net.ipv4.ip_forward=1

    # sysctl -p
    ```

##相关链接
  - [keepalived 官方文档](https://www.keepalived.org/manpage.html)
  - [负载均衡及服务器集群](https://www.keepalived.org/pdf/sery-lvs-cluster.pdf)
  - [keepalived 基本使用(主备模式)](https://blog.51cto.com/disheng/1718112)
  - [配置keepalived ping不通 解决办法](https://blog.csdn.net/iflow/article/details/78594972)
  - [Linux下Keepalived安装与配置(主要看选项说明)](https://blog.csdn.net/bbwangj/article/details/80346428)
  - [CentOS 7 配置 Keepalived 实现双机热备(一篇很细致的博客)](https://qizhanming.com/blog/2018/05/17/how-to-config-keepalived-on-centos-7)
  - [Install LVS and keepalived on CentOS7(安装时可以参照的博客)](https://robinye.com/2019/02/16/Install_LVS_Keepalived_CentOS7/)
  - [LVS+KeepAlived+Nginx高可用实现方案(较完整的配置示例)](https://blog.csdn.net/lupengfei1009/article/details/86514445#KeepAlived_20)
