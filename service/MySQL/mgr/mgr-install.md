

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

**master**
```sql
n5zh#@ohsMH)NCF!
-- hostnamectl set-hostname mysql01

SET SQL_LOG_BIN=0;
alter user 'root'@'localhost' identified by '123456';
create user 'repl'@'%' identified by '123456';
GRANT replication slave ON *.* TO repl@'%';
flush privileges;
reset master;
SET SQL_LOG_BIN=1;


change master to master_user='repl', master_password='123456' for channel 'group_replication_recovery';
install plugin group_replication SONAME 'group_replication.so';
show plugins;
set global group_replication_bootstrap_group=on;
start group_replication;
set global group_replication_bootstrap_group=off;

SELECT * from performance_schema.replication_group_members;
select * from mysql.user\G;

show variables like '%whitelist%';
There was an error when connecting to the donor server. Please check that group_replication_recovery channel credentials and all MEMBER_HOST column values of performance_schema.replication_group_members table are correct and DNS resolvable.'
```

node02
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