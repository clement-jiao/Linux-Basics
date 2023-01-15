## mha MHA集群部署教程
略

```sql
stop slave;
reset slave;
show slave status;

CHANGE REPLICATION SOURCE TO
    source_host='10.0.0.1',
    source_port=3306,
    source_user='mha',
    source_password='WUh65P0pl7m1V0m',
    source_log_file='binlog.000001',
    source_log_pos=937990386;
START REPLICA;
show slave status;


stop replica;
reset slave all;
reset master;
show slave status;

```


```bash
masterha_check_ssh --conf /etc/masterha/app1.cnf
masterha_check_repl --conf /etc/masterha/app1.cnf
nohup masterha_manager --conf=/etc/masterha/app1.cnf --remove_dead_master_conf --ignore_last_failover < /dev/null > /var/log/masterha/app1/manager.log 2>&1 &
masterha_stop --conf /etc/masterha/app1.cnf
```

### 搬运地址
MHA集群部署教程
https://www.linuxe.cn/post-464.html

MySQL 主从复制原理不再难
https://www.cnblogs.com/rickiyang/p/13856388.html

mysql8.0+ config replica: Configure Database Replication[0]
https://www.linode.com/docs/guides/configure-master-master-mysql-database-replication/

Orchestrator使用
https://www.cnblogs.com/zhoujinyi/p/10394389.html