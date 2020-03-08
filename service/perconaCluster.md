<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-17 16:48:31
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-24 05:13:29
 -->
#使用 Percona 搭建高可用的 MySQL 数据库

## 简介
  - Percona是一个公司的名称，主要做 MySQL 的二次开发
  - 他的集群解决方案叫Percona XtraDB Cluster，简称PXC
  - 他的备份解决方案叫Percona XtraBackup

## 架构图
  - 虚线是模拟右侧proxy宕机的情景，红色的虚IP会飘到左边的proxy上
  - application一律使用域名访问数据库，由DNS服务器解析到红黄两个虚拟IP上
  - 由于三个数据库都是可读写的，所以代理到哪个服务器都可以
    ![percona架构图](/images/software/pxc架构图.png)

## 版本
  PXC：5.7
  CentOS：7.6

## Percona安装与配置
  - 在三台主机上配置yum源
    ```bash
    yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm                    # 安装yum源

    sed -i 's$http://repo.percona.com/percona$https://mirrors.ustc.edu.cn/percona$g'   # 替换国内源

    sed -i 's$gpgcheck = 1$gpgcheck = 0$g'              # 关闭秘钥校验
    ```
    >更新过yum源后，会在 /etc/yum.repos.d/ 下生成 percona-release.repo

  - 关闭 selinux 和 Firewalls
    ```bash
    setenforce 0

    systemctl stop firewalls.service
    ```

  - 卸载 MySQL/MariaDB
    >由于 Percona-XtraDB-Cluster-shared-57-5.7.23-31.31.1.el7.x86_64.rpm  有一个冲突：

    ```bash
    error: Failed dependencies:
      mariadb-libs
         >=
      5.5.37 is obsoleted by Percona-XtraDB-Cluster-shared-57-5.7.23-31.31.1.el7.x86_64

    systemctl stop mariadb/mysql        # 停止MySQL/MariaDB

    yum remove mariadb-libs             # 卸载lib库

    yum remove mariadb-libs mariadb-service mariadb-client      # 卸载 MariaDB
    ```

  - 安装
    ```bash
    yum -y install Percona-XtraDB-Cluster-57
    ```

  - 查看密码
    ```bash
    systemctl start mysql # 数据库不建议开机启动
    grep 'temporary password' /var/log/mysqld.log
    ```

  - 连接数据库
    ```bash
    mysql -u root -p
    ```

  - 添加 root 用户远程的访问权限
    ```sql
    mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin';
    Query OK, 0 rows affected (0.01 sec)

    mysql> GRANT ALL PRIVILEGES ON *.* TO root@"192.168.0.%" IDENTIFIED BY "admin";
    Query OK, 0 rows affected, 1 warning (0.01 sec)
    ```

  - 添加SST用户
    ```sql
    mysql> CREATE USER 'sstuser'@'localhost' IDENTIFIED BY 'mysql';
    Query OK, 0 rows affected (0.00 sec)    /*只允许本地登录*/

    mysql> GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO 'sstuser'@'localhost';
    Query OK, 0 rows affected (0.00 sec)    /*设置sstuser 用户权限*/

    mysql> FLUSH PRIVILEGES;                /*刷新权限*/
    Query OK, 0 rows affected (0.01 sec)
    ```

  - 停止服务，修改配置文件
    ```bash
    systemctl stop mysql
    ```

  - 首先修改 /etc/percona-xtradb-cluster.conf.d/wsrep.cnf
    ```conf
    # vim /etc/percona-xtradb-cluster.conf.d/wsrep.cnf

    [mysqld]
    # Path to Galera library
    wsrep_provider=/usr/lib64/galera3/libgalera_smm.so

    # Cluster connection URL contains IPs of nodes
    #If no IP is found, this implies that a new cluster needs to be created,
    #in order to do that you need to bootstrap this node
    # 群集连接URL包含节点的IP如果未找到IP，则表示需要创建新群集，为此，您需要引导此节点
    # {这里可以写域名或者IP地址，第一个ip为主节点,cluster内需保持一致}
    wsrep_cluster_address=gcomm://192.168.0.157,192.168.0.109,192.168.0.54

    # In order for Galera to work correctly binlog format should be ROW
    # 为了让Galera正常工作，binlog格式应该是ROW
    binlog_format=ROW

    # MyISAM storage engine has only experimental support
    # MyISAM 存储引擎只有实验环境支持：InnoDB、MyIsam、、Memory、Mrg_Myisam、Blackhole
    default_storage_engine=InnoDB

    # Slave thread to use
    # slave 节点线程
    wsrep_slave_threads= 8

    wsrep_log_conflicts

    # This changes how InnoDB autoincrement locks are managed and is a requirement for Galera
    # 这改变了InnoDB自动增量锁的管理方式，是Galera的要求
    innodb_autoinc_lock_mode=2

    # Node IP address
    # 节点 IP 地址
    # {这个可以写可以不写}
    wsrep_node_address=10.210.149.25
    # Cluster name
    # cluster 名称：其他节点需保持一致
    wsrep_cluster_name=pxc-cluster

    #If wsrep_node_name is not specified,  then system hostname will be used
    # 如果未指定wsrep_node_name，则将使用系统主机名
    # 子节点名称：需在 cluster 中保持唯一
    wsrep_node_name=pxc-cluster-node-10-210-149-25

    #pxc_strict_mode allowed values: DISABLED,PERMISSIVE,ENFORCING,MASTER
    # pxc 严格模式 允许的值：DISABLED,PERMISSIVE,ENFORCING,MASTER
    pxc_strict_mode=ENFORCING

    # SST method
    # sst 用户 备份/传输模式：XtraBackup-v2
    wsrep_sst_method=xtrabackup-v2

    #这项一定要写
    # sst 用户验证：
    #Authentication for SST method
    wsrep_sst_auth="sstuser:mysql"
    ```

  - 启动主节点
    ```bash
    systemctl start mysql@bootstrap.service
    ```

  - 在其他节点上修改/etc/percona-xtradb-cluster.conf.d/wsrep.cnf
  - 在其他结点上修改/etc/percona-xtradb-cluster.conf.d/mysqld.cnf
    ```conf
    # vim /etc/percona-xtradb-cluster.conf.d/mysqld.cnf

    # 节点1
    [mysqld]
    server-id=2

    # 节点2
    [mysqld]
    server-id=3
    ```
  - 在其他上启动mysql
    ```bash
    systemctl start mysql
    ```

  - 随便找一个节点检查集群情况
    ```sql
    mysql> show status like 'wsrep_cluster_size';

    mysql> show status like 'wsrep_cluster%';
    ```

  - 主节点down掉后加入 cluster
    ```bash
    systemctl start mysql
    ```

    >注意：如果cluster已经启动，主节点down机想重新加入这个集群，直接启动mysql即可

  - 如果这个集群中最后的节点也down机了，在任何一个节点都可以启动集群，重新启动集群需要执行
    ```bash
    systemctl start mysql@bootstrap.service
    ```

    > 然后在其他节点执行 systemctl start mysql

## Proxy安装与配置
  - 可以选用nginx/lvs/haproxy任何一种，不过他们的原理不太一样Nginx和haprxoy是代理，LVS是转发
  - Haproxy的配置看这个：[使用percona搭建高可用的MySQL数据库](https://www.cnblogs.com/demonzk/p/8444450.html)
  - Nginx的高可用配置看这个：[Keepalive + Nginx高可用](https://www.jianshu.com/p/f7ef05d0e1f6)


## 链接地址
  - [PXC - 官方文档](https://www.percona.com/doc/percona-xtradb-cluster/5.7/index.html)
  - [导入无主键表错误:prohibits use of DML command on a table](http://liking.site/2018/12/06/mysql-pxc%E9%9B%86%E7%BE%A4%E5%A6%82%E4%BD%95%E5%AF%BC%E5%85%A5%E6%97%A0%E4%B8%BB%E9%94%AE%E8%A1%A8/)


