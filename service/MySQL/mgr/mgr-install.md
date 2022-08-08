### mgr

**selector**
```sql
-- 组复制视图
SELECT * from performance_schema.replication_group_members;
-- +---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
-- | CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION | MEMBER_COMMUNICATION_STACK |
-- +---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
-- | group_replication_applier | 02e2e5de-0971-11ed-bb6b-0050560100c1 | 10.0.0.8    |        3306 | ONLINE       | SECONDARY   | 8.0.29         | XCom                       |
-- | group_replication_applier | 25226055-0971-11ed-b38f-0050560100c0 | 10.0.0.7    |        3306 | ONLINE       | SECONDARY   | 8.0.29         | XCom                       |
-- | group_replication_applier | dfac4efa-0970-11ed-ad7d-0050560100bf | 10.0.0.6    |        3306 | ONLINE       | PRIMARY     | 8.0.29         | XCom                       |
-- +---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
-- 3 rows in set (0.00 sec)

-- 当前节点状态
SELECT * FROM sys.gr_member_routing_candidate_status;

-- +------------------+-----------+---------------------+----------------------+
-- | viable_candidate | read_only | transactions_behind | transactions_to_cert |
-- +------------------+-----------+---------------------+----------------------+
-- | YES              | YES       |                   0 |                    0 |
-- +------------------+-----------+---------------------+----------------------+
-- 1 row in set (0.01 sec)

-- 缓冲池大小
SELECT @@innodb_buffer_pool_size/1024/1024/1024;

-- +------------------------------------------+
-- | @@innodb_buffer_pool_size/1024/1024/1024 |
-- +------------------------------------------+
-- |                          16.000000000000 |
-- +------------------------------------------+
-- 1 row in set (0.00 sec)
```



alter user 'root'@'localhost' identified by 'n5zh#@ohsMH)NCF!'; flush privileges;
create user 'repl'@'%' identified with mysql_native_password by '123456';

create user 'proxysql_monitor'@'%' identified by '123456';
grant select,replication client on *.* to 'proxysql_monitor'@'%';
flush privileges;



```bash
# 重置 MySQL
rm -rf /var/lib/mysql/* /var/log/mysqld.log && systemctl start mysqld && cat /var/log/mysqld.log |grep password
```

**node01(master)**
```sql
-- hostnamectl set-hostname mysql01

SET SQL_LOG_BIN=0;
alter user 'root'@'localhost' identified by '123456';
create user 'repl'@'%' identified by '123456';
GRANT replication slave ON *.* TO repl@'%';
flush privileges;
reset master;
SET SQL_LOG_BIN=1;

change master to master_user='repl', master_password='123456' for channel 'group_replication_recovery';
-- install plugin group_replication SONAME 'group_replication.so'; -- 默认插件(大概)
-- show plugins;
set global group_replication_bootstrap_group=on;
start group_replication;
set global group_replication_bootstrap_group=off;

SELECT * from performance_schema.replication_group_members;
select * from mysql.user\G;
show variables like '%whitelist%';
```

node02,node03
```sql
-- hostnamectl set-hostname mysql02
SET SQL_LOG_BIN=0;
alter user 'root'@'localhost' identified by '123456';
create user 'repl'@'%' identified by '123456';
GRANT replication slave ON *.* TO repl@'%';
flush privileges;
reset master;
SET SQL_LOG_BIN=1;

change master to master_user='repl', master_password='123456' for channel 'group_replication_recovery';
-- install plugin group_replication SONAME 'group_replication.so'; -- 默认插件(大概)
-- show plugins;

start group_replication;
```

### 切换到多主模式

MGR切换模式需要重新启动组复制，因些需要在所有节点上先关闭组复制，设置 group_replication_single_primary_mode=OFF 等参数，再启动组复制。

**停止组复制(所有节点执行)：**
```sql
mysql> stop group_replication;
-- 重点在这：single_primary_mode=OFF; 其余方法步骤一致
mysql> set global group_replication_single_primary_mode=OFF;
mysql> set global group_replication_enforce_update_everywhere_checks=ON;
```
```sql
-- 随便选择某个节点执行
mysql> SET GLOBAL group_replication_bootstrap_group=ON;
mysql> START GROUP_REPLICATION;
mysql> SET GLOBAL group_replication_bootstrap_group=OFF;
```
```sql
-- 其他节点执行
mysql> START GROUP_REPLICATION;
```
```sql
-- 查看组信息，所有节点的 MEMBER_ROLE 都为 PRIMARY
mysql>  SELECT * FROM performance_schema.replication_group_members;
-- +---------------------------+--------------------------------------+--------------+-------------+--------------+-------------+----------------+
-- | CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST  | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
-- +---------------------------+--------------------------------------+--------------+-------------+--------------+-------------+----------------+
-- | group_replication_applier | 8daa9f72-4e1c-11e9-8bb6-000c295b4eb7 | 10.253.3.101 |        3306 | ONLINE       | PRIMARY     | 8.0.11         |
-- | group_replication_applier | bffc8972-4e1c-11e9-a949-000c29124ee9 | 10.253.3.102 |        3306 | ONLINE       | PRIMARY     | 8.0.11         |
-- | group_replication_applier | c0cde392-4e1c-11e9-b99e-000c291fa60d | 10.253.3.103 |        3306 | ONLINE       | PRIMARY     | 8.0.11         |
-- +---------------------------+--------------------------------------+--------------+-------------+--------------+-------------+----------------+
-- 3 rows in set (0.00 sec)

-- 可以看到所有节点状态都是online，角色都是PRIMARY，MGR多主模式搭建成功。
```

### 切换回单主
```sql
-- 所有节点执行
mysql> stop group_replication;
mysql> set global group_replication_enforce_update_everywhere_checks=OFF;
mysql> set global group_replication_single_primary_mode=ON;


-- 主节点（10.253.3.101）执行
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group=OFF;

-- 从节点（10.253.3.102、10.253.3.103）执行
START GROUP_REPLICATION;

-- 查看MGR组信息
mysql> SELECT * FROM performance_schema.replication_group_members;

-- +---------------------------+--------------------------------------+--------------+-------------+--------------+-------------+----------------+
-- | CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST  | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
-- +---------------------------+--------------------------------------+--------------+-------------+--------------+-------------+----------------+
-- | group_replication_applier | 8daa9f72-4e1c-11e9-8bb6-000c295b4eb7 | 10.253.3.101 |        3306 | ONLINE       | PRIMARY     | 8.0.11         |
-- | group_replication_applier | bffc8972-4e1c-11e9-a949-000c29124ee9 | 10.253.3.102 |        3306 | ONLINE       | SECONDARY   | 8.0.11         |
-- | group_replication_applier | c0cde392-4e1c-11e9-b99e-000c291fa60d | 10.253.3.103 |        3306 | ONLINE       | SECONDARY   | 8.0.11         |
-- +---------------------------+--------------------------------------+--------------+-------------+--------------+-------------+----------------+
-- 3 rows in set (0.00 sec)
```


参考资料：
kubeDB：https://kubedb.com/docs/v2021.03.17/guides/proxysql/overview/configure-proxysql/
切换模式：https://blog.51cto.com/u_14286115/3324366