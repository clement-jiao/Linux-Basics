#!/bin/bash
#################################################################
# 作者：clement
# 日期：2023-02-19
# 作用：不停机锁表自动配置主从同步；
# 依赖： mysqldump 、修改配置文件适当加入以下信息

# mysql config file
# [mysqld]
# user=mysql
# expire-logs-days = 3

# binlog_format = ROW
# log-bin=mysql-bin
# server-id=20

# replicate-do-db=jimmychoo
#################################################################
# work_dir=$(dirname ${BASH_SOURCE[0]})
work_dir=/bak
sqlfile_name=master_back

master_user=root
master_password=''
master_host=10.0.0.17
master_port=3306
master_db_name="db1 db2"

slave_user=root
slave_password=''
slave_host=127.0.0.1
slave_port=3306

# change work dir
mkdir -pv /bak
cd /bak;
# cd /var/lib/mysql/back;

# backup master data
echo "/usr/bin/mysqldump -u ${master_user} -p${master_password} -h ${master_host} -P ${master_port} --single-transaction --source-data=2 --databases ${master_db_name} > ${work_dir}/${sqlfile_name}.sql"
/usr/bin/mysqldump -u ${master_user} -p${master_password} -h ${master_host} -P ${master_port} --single-transaction --source-data=2 --databases ${master_db_name} > ${work_dir}/${sqlfile_name}.sql

# bin log info
master_log_pos=$(grep -m 1 MASTER_LOG_POS ${sqlfile_name}.sql | awk -F = '{ print $NF }')
master_log_pos=${master_log_pos%;}
master_log_file=$(grep -m 1 MASTER_LOG_FILE ${sqlfile_name}.sql | awk -F "'" '{ print $2 }')
LOG_LEVEL=2

function log_info(){
    content="[INFO] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 2  ] && echo -e "\033[32m"  ${content} "\033[0m"
}

function log_warn(){
    content="[WARN] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 3  ] && echo -e "\033[33m" ${content} "\033[0m"
}

function log_err(){
    content="[ERROR] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 4  ] && echo -e "\033[31m" ${content} "\033[0m"
}

function exec_sql(){
    if [ $1 == "master" ];then
        echo "master SQL: /usr/bin/mysql -u ${master_user} -h ${master_host} -P ${master_port} -p ${master_password} -e '$2'"
        /usr/bin/mysql -u ${master_user} -h ${master_host} -P ${master_port} -p${master_password} -e "$2"
    else
        echo "slave SQL:  /usr/bin/mysql -u ${slave_user} -h ${slave_host} -P ${slave_port} -p ${slave_password} -e '$2'"
        /usr/bin/mysql -u ${slave_user} -h ${slave_host} -P ${slave_port} -p${slave_password} -e "$2"
    fi

    # check exec sql
    if [ "$?" == 0 ] ; then
        log_info "exec sql success!"
    else
        log_err "sql err, please check sql"
        exit 1
    fi
}

for db in ${master_db_name}; do
    log_info "create database: ${db}"
    exec_sql "slave" "CREATE DATABASE ${db} CHARACTER SET 'utf8mb4';"
done

exec_sql "slave" "source ${work_dir}/${sqlfile_name}.sql"

exec_sql "slave" "stop slave;"
exec_sql "slave" "reset master;"
exec_sql "slave" "reset slave all;"
exec_sql "slave" "change master to master_host='${master_host}',master_user='${master_user}',master_port=${master_port},master_password='${master_password}',master_log_file='${master_log_file}',master_log_pos=${master_log_pos};"
exec_sql "slave" "start slave;"
sleep 30
exec_sql "slave" "show slave status\G;"

echo "如果成功记得手动 read_only=1"

# mysql -u root -p -h 127.0.0.1 -P 3307 -e "change master to master_host='127.0.0.1',master_user='root',master_port=3306,master_password='123456',master_log_file='mysql-bin.000001',master_log_pos=157;"
# /usr/bin/mysqldump -u root -p123456 -h 127.0.0.1 -P 3306 --single-transaction --source-data=2 --databases jimmychoo > jimmychoo.sql
