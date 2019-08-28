<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-25 02:05:08
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-25 03:46:16
 -->
#zabbix 监控 php-fpm

## 修改配置文件
  - 配置文件组成

    ```conf
    www.conf                                    # php-fpm 配置文件
    default.conf                                # nginx 配置文件：状态页路径通过 nginx 透出
    php-fpm.xml.sh                              # 探测 php-fpm 状态(xml格式)
    zabbix_agentd.conf                          # zabbix-agent 配置文件
    userparameter_php-fpm.conf                  # 定义 zabbix-agent 键值的文件，命名规则为：userparameter_{监控的服务或其他}.conf
    ```

  - 修改 zabbix-agent 配置文件
    以下为 zabbix-agent 必填项：
    ```bash
    # vim /etc/zabbix/zabbix_agentd.conf

    # [root@nginx-node-2 zabbix]# egrep -v "(^$|^#)" /etc/zabbix/zabbix_agentd.conf

    # PidFile=/var/run/zabbix/zabbix_agentd.pid
    # LogFile=/var/log/zabbix/zabbix_agentd.log
    # LogFileSize=1                             # 限制 zabbix-agent 日志大小
    # Server=192.168.0.74                       # 指定 zabbix-server 地址
    # ServerActive=192.168.0.74                 # 检查 zabbix-server 活动情况，默认为 disabled
    # Hostname=nginx-node-2                     # 指定本机 hostname
    # Include=/etc/zabbix/zabbix_agentd.d/*.conf
    ```

  - php
    ```conf
    # vim /etc/opt/remi/php73/php-fpm.d/www.conf

    [root@php-node-1 php73]# egrep -v '(^$|^#|^;)' php-fpm.d/www.conf
    [www]
    user = nginx
    group = nginx
    listen = 0.0.0.0:9000               # 监听端口：不能写多个地址，只好设置为任意地址
    listen.owner = nobody               # nginx 访问时的用户
    listen.group = nobody               # nginx 访问时的组
    listen.mode = 0660                  # nginx 访问的权限
    listen.acl_users = nginx
    listen.acl_groups = nginx
    listen.allowed_clients = 192.168.0.95,192.168.0.88,192.168.0.33
    pm = dynamic
    pm.max_children = 50                # 最大子进程
    pm.start_servers = 5
    pm.min_spare_servers = 5
    pm.max_spare_servers = 35
    pm.status_path = /status-1          # 开启 php-fpm 状态页：刚刚写在 nginx 配置文件中的地址，默认为 disable
    slowlog = /var/opt/remi/php73/log/php-fpm/www-slow.log    # php 的慢日志
    php_admin_value[error_log] = /var/opt/remi/php73/log/php-fpm/www-error.log
    php_admin_flag[log_errors] = on
    php_value[session.save_handler] = files
    php_value[session.save_path]    = /var/opt/remi/php73/lib/php/session
    php_value[soap.wsdl_cache_dir]  = /var/opt/remi/php73/lib/php/wsdlcache
    ```

  - nginx：
    开启 php-fpm 状态检测页路径：让 nginx 允许通过此路径访问 php-fpm 状态页
    ```conf
    # vim

    location ~ ^/status-1 {               # php-node-1节点
        access_log off;                   # 关闭访问日志
        allow 192.168.0.0/24;             # 仅允许192.168.0.0/24网段访问
        deny all;                         # 禁止所有地址访问
        fastcgi_pass 192.168.0.120:9000;  # php-fpm 地址:端口
        fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        include        fastcgi_params;
      }

    location ~ ^/status-2 {               # # php-node-2节点
        access_log off;
        allow 192.168.0.0/24;
        deny all;
        fastcgi_pass 192.168.0.64:9000;
        fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        include        fastcgi_params;
      }

    location ~ ^/status-3 {
        access_log off;
        allow 192.168.0.0/24;
        deny all;
        fastcgi_pass 192.168.0.135:9000;
        fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        include        fastcgi_params;
      }
    ```

  - userparameter_php-fpm.conf
    zabbix-agent 的键值定义文件
    ```conf
    # vim /etc/zabbix/zabbix_agentd.d/userparameter_php-fpm.conf

    UserParameter=php-fpm.status[*],/etc/zabbix/scripts/php-fpm.xml.sh $1
    ```
  - php-fpm.xml.sh
    ```bash
    HOST="192.168.0.163"
    PORT="80"
    status="status-1"

    function query() {
        curl -s http://${HOST}:${PORT}/${status}?xml | grep "<$1>" | awk -F'>|<' '{ print $3}'
    }

    if [ $# == 0 ]; then
        echo $"Usage $0 {pool|process-manager|start-time|start-since|accepted-conn|listen-queue|max-listen-queue|listen-queue-len|idle-processes|active-processes|total-processes|max-active-processes|max-children-reached|slow-requests}"
        exit
    else
        query "$1"
    fi
    ```

  - zabbix_agent.conf
    ```conf
    [root@php-node-1 zabbix]# egrep -v "(^$|^#|;)" zabbix_agentd.conf

    PidFile=/var/run/zabbix/zabbix_agentd.pid
    LogFile=/var/log/zabbix/zabbix_agentd.log
    LogFileSize=1                 # 限制 zabbix-agent 日志大小1M
    Server=192.168.0.74           # zabbix 服务端IP
    ServerActive=192.168.0.74     # 检测活动的 zabbix 服务端：设置主动模式时必填项
    Hostname=php-node-1           # 设置主机名(本地hostname)：设置主动模式时必填项
    Include=/etc/zabbix/zabbix_agentd.d/*.conf
    ```

  - userparameter_php-fpm.conf
    ```conf
    UserParameter=php-fpm.status[*],/etc/zabbix/scripts/php-fpm.xml.sh $1
    ```

## 重启服务
  - php
    ```bash
    systemctl restart php73-php-fpm
    ```
  - nginx
    ```bash
    systemctl restart nginx
    ```
  - zabbix-agent
    ```bash
    systemctl restart zabbix-agent
    ```

## 在服务端验证脚本
  - zabbix-agent
    ```bash
    yum install -y zabbix-get

    zabbix_get -s 192.168.0.120 -k 'php-fpm.status[pool]'       # 在服务端运行： zabbix_get -s 被监控端ip -k '被监控端k[值]'
    www
    ```

## 在 zabbix-web 中配置 php-fpm
