<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-25 03:45:12
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-28 13:40:33
 -->

#zabbix 监控 haproxy


## 修改配置文件

  - 配置文件组成
    ```conf
    haproxy.cfg                                 # haproxy 配置文件
    haproxy-nginx.socket.sh                     # 探测 php-fpm 状态(xml格式)
    zabbix_agentd.conf                          # zabbix-agent 配置文件
    userparameter_haproxy_nginx.conf            # 定义 zabbix-agent 键值的文件，命名规则为：userparameter_{监控的服务或其他}.conf
    ```

  - haproxy.cfg
    由于 haproxy 的 api 是通过 socket 透出的，所以需要 socat 命令来查看，在 web 页面中也能看到，但是脚本无法通过权限验证。
    ```conf
    # vim /etc/haproxy/haproxy.cfg
    global
        log         127.0.0.1 local2
        chroot      /var/opt/rh/rh-haproxy18/lib/haproxy
        pidfile     /var/run/rh-haproxy18-haproxy.pid
        maxconn     4096
        user        haproxy
        group       haproxy
        daemon
        # turn on stats unix socket
        stats socket /var/opt/rh/rh-haproxy18/lib/haproxy/stats mode 600 level admin   # 主要是为了修改权限和运行级别。
    ```

  - haproxy-nginx.socket.sh
    ```bash
    # chmod +x /etc/zabbix/scripts/haproxy-nginx.socket.sh

    socket="/var/opt/rh/rh-haproxy18/lib/haproxy/stats"

    function query() {
        echo "show" "$2"| socat  /var/opt/rh/rh-haproxy18/lib/haproxy/stats  stdio| grep -i "$1"":" | awk -F ': ' '{print $2}' | sed s/[[:space:]]//g
        # 输出信息 | 查看 stats 信息 | 过滤 某个值 (不区分大小写) | 以'：'为分隔符，取第二列| 去除所有空格
        # 还可以 echo help。
    }
    if [ $# == 0 ]; then
        echo $"Usage $0 need a parameter"
        exit
    else
        query "$1" "$2"
    fi
    ```

  - zabbix_agentd.conf
    ```conf
    [root@php-node-1 zabbix]# egrep -v "(^$|^#|;)" zabbix_agentd.conf

    PidFile=/var/run/zabbix/zabbix_agentd.pid
    LogFile=/var/log/zabbix/zabbix_agentd.log
    LogFileSize=1                 # 限制 zabbix-agent 日志大小1M
    Server=192.168.0.74           # zabbix 服务端IP
    ServerActive=192.168.0.74     # 检测活动的 zabbix 服务端：设置主动模式时必填项
    Hostname=php-node-1           # 设置主机名(本地hostname)：设置主动模式时必填项
    AllowRoot=1                   # 需要 root 权限启动socat命令
    Include=/etc/zabbix/zabbix_agentd.d/*.conf
    ```

  - userparameter_haproxy_nginx.conf
    ```conf
    UserParameter=haproxy-nginx.status[*],/etc/zabbix/scripts/haproxy-nginx.socket.sh $1
    ```

## 重启服务
  - haproxy
    ```bash
    systemctl restart haproxy
    ```

  - zabbix-agent
    ```bash
    systemctl restart zabbix-agent
    ```

## 在 zabbix-web 中配置 haproxy


## 相关链接
  - [GitHub-zabbix-haproxy](https://github.com/anapsix/zabbix-haproxy)
