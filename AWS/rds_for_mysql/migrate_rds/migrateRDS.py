import time
import boto3
import pymysql
import datetime
import argparse
from icecream import ic

try:
    import config
except ModuleNotFoundError:
    print("not found config file")
    exit(1)

proxysql_ip = config.proxysql_ip

region_id = config.region_id
region_name = config.region_name

master_db_port = config.master_db_port
master_db_username = config.master_db_username
master_db_password = config.master_db_password
master_db_Instance_Identifier = config.master_db_Instance_Identifier

slave_db_port = config.slave_db_port
slave_db_username = config.slave_db_username
slave_db_password = config.slave_db_password
slave_db_Instance_Identifier = config.slave_db_Instance_Identifier

master_proxysql_port = config.master_proxysql_port
master_proxysql_username = config.master_proxysql_username
master_proxysql_password = config.master_proxysql_password
master_proxysql_endpoint = proxysql_ip

admin_proxysql_port = config.admin_proxysql_port
admin_proxysql_username = config.admin_proxysql_username
admin_proxysql_password = config.admin_proxysql_password
admin_proxysql_endpoint = proxysql_ip

aws_access_key_id = config.aws_access_key_id
aws_secret_access_key = config.aws_secret_access_key

master_db_endpoint = f"{master_db_Instance_Identifier}.{region_id}.{region_name}.rds.amazonaws.com"
slave_db_endpoint = f"{slave_db_Instance_Identifier}.{region_id}.{region_name}.rds.amazonaws.com"

master_db_config = dict(
    host=master_db_endpoint, port=master_db_port, user=master_db_username,
    passwd=master_db_password, cursorclass=pymysql.cursors.DictCursor)
slave_db_config = dict(
    host=slave_db_endpoint, port=slave_db_port, user=slave_db_username,
    passwd=slave_db_password, cursorclass=pymysql.cursors.DictCursor)
admin_proxysql_config = dict(
    host=admin_proxysql_endpoint, port=admin_proxysql_port, user=admin_proxysql_username,
    passwd=admin_proxysql_password, cursorclass=pymysql.cursors.DictCursor)
master_proxysql_config = dict(
    host=master_proxysql_endpoint, port=master_proxysql_port, user=master_proxysql_username,
    passwd=master_proxysql_password, cursorclass=pymysql.cursors.DictCursor)


def get_mysql_connection(mysql_config) -> pymysql.connect.cursor:
    """
    传入库连接配置，返回 connect.cursor，后边可以优化成一个公共类
    :param mysql_config: 里面指定了 DictCursor 对象，返回是一个 Dict 对象，如果没有则返回 None。
    :return: connect.cursor
    """
    try:
        conn = pymysql.connect(**mysql_config, autocommit=True).cursor()
    except Exception as e:
        print(str(e))
        print(f"db conn err: {mysql_config}")
    else:
        return conn


def get_read_replica_db_binlog():
    """
    获取 slave 的 binlog 日志位置，为后续同步做准备。
    SQL: "show slave status;": 其中有与 master 连接的状态等信息。
        Master_Log_File：mysql-bin-changelog.157167
        Exec_Master_Log_Pos：120

    rds_stop_replication: aws 官方不允许自行修改 binlog 复制，所以使用了官方提供的存储过程。
        https://docs.aws.amazon.com/zh_cn/AmazonRDS/latest/UserGuide/mysql_rds_stop_replication.html

    :return:
        # 也许应该返回个 dict ？
        master_log_file: mysql-bin-changelog.157167
        exec_master_log_pos: 120
    """
    slave_db_cursor = get_mysql_connection(slave_db_config)

    stop_replication_sql = "CALL mysql.rds_stop_replication;"
    slave_db_cursor.execute(stop_replication_sql)
    ic("rds_stop_replication success")

    slave_db_cursor.execute("show slave status;")
    slave_status: dict = slave_db_cursor.fetchone()

    if slave_status:
        master_log_file = slave_status.get("Master_Log_File")
        exec_master_log_pos = slave_status.get("Exec_Master_Log_Pos")
        slave_db_cursor.close()
        ic(master_log_file, exec_master_log_pos)
        return master_log_file, exec_master_log_pos


def set_read_replica_external_master(binlog, log_pos):
    """
    拿到传入的 binlog 日志位置信息，对 slave(已经提升为主实例的 db) 重新开始 binlog 复制。
    reset_external_master：重新配置/重置 MySQL 数据库实例，使其不再是在 Amazon RDS 之外运行的某个 MySQL 实例的只读副本。
        https://docs.aws.amazon.com/zh_cn/AmazonRDS/latest/UserGuide/mysql_rds_reset_external_master.html

    rds_set_external_master：将 MySQL 数据库实例配置为在 Amazon RDS 之外运行的 MySQL 实例的只读副本/主从同步副本。
        https://docs.aws.amazon.com/zh_cn/AmazonRDS/latest/UserGuide/mysql_rds_set_external_master.html
        需要传入对方连接配置、binlog 和 binlog_pos 信息。

    rds_start_replication：从 MySQL 数据库实例中启动复制。
        https://docs.aws.amazon.com/zh_cn/AmazonRDS/latest/UserGuide/mysql_rds_start_replication.html

    :param binlog:
    :param log_pos:
    :return:
    """
    start_replication = "CALL mysql.rds_start_replication;"
    reset_external_master = "CALL mysql.rds_reset_external_master;"
    set_external_master = """CALL mysql.rds_set_external_master (
    '{host}', {port},
    '{user}', '{passwd}',
    '{binlog}', {log_pos},0);
    """.format(**master_db_config, binlog=binlog, log_pos=log_pos)

    slave_db_cursor = get_mysql_connection(slave_db_config)

    slave_db_cursor.execute(reset_external_master)
    ic("reset master success")
    slave_db_cursor.execute(set_external_master)
    ic("rds set external master success")
    # 等待与对方同步/连接完成。
    time.sleep(2)
    ic("sleep 2s")

    slave_db_cursor.execute(start_replication)
    ic("start replication")

    for i in range(10):
        # 等待 30 秒后如果还没同步成功，则需要手动检查，不对后面配置有影响。
        print(f"waiting connect master: {i * 3}", end="\r")

        slave_db_cursor.execute("show slave status;")
        # 使用 fetch one：理论上应有且只有一个连接状态，不存在 slave 对应多个主库的情况。
        slave_status_info = slave_db_cursor.fetchone()

        # 取 "show slave status;" 信息中："Slave_IO_State", "Slave_SQL_Running" 的信息，两个均为 yes，则连接成功，手动配置也是如此。
        slave_io_state, slave_io, slave_sql = slave_status_info.get("Slave_IO_State"), slave_status_info.get(
            "Slave_IO_Running"), slave_status_info.get("Slave_SQL_Running")
        ic(slave_io_state, slave_io, slave_sql)

        if slave_io_state == "Waiting for master to send event" and slave_io == slave_sql:
            # 状态为："Waiting for master to send event" 时，则说明连接成功，且在等待 master 发送 SQL 等内容。
            slave_db_cursor.close()
            print("connect success!", slave_io_state)
            break

        if i == 9:
            # 已等待 30 秒：
            slave_db_cursor.close()
            print(f"connect master db failed:{slave_io_state}\n slave_io:{slave_io}, slave_sql:{slave_sql}")
            print("script exit")
            exit(1)
        ic("sleep 3s")
        time.sleep(3)


def promote_read_replica_db():
    """
    将只读副本(slave)，提升为主实例，提升时应保持网络通畅，即同时为内网/公开访问，公开访问时安全组应开放相应端口。

    access_key:
        Overview:
            Boto3 credentials can be configured in multiple ways. Regardless of the source or sources that you choose,
            you must have both AWS credentials and an AWS Region set in order to make requests.
        https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html
        
    promote_read_replica：
        Overview：
            Promotes a read replica DB instance to a standalone DB instance.
        https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds.html#RDS.Client.promote_read_replica

    :return:
    """
    
    slave_binlog = get_read_replica_db_binlog()
    if slave_binlog:
        binlog, log_pos = slave_binlog
    else:
        binlog, log_pos = (0, 0)

    ic(f"slave_binlog: {binlog}, log_pos: {log_pos},slave_binlog: {slave_binlog}")

    if binlog and log_pos:
        client = boto3.client(
            'rds',
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            region_name=region_name
        )
        promote_response = client.promote_read_replica(
            DBInstanceIdentifier=slave_db_Instance_Identifier,
            BackupRetentionPeriod=3
        )
        ic("promote_response:", promote_response)
        while True:
            # 循环查 slave 状态，直到 DBInstanceStatus 为 available 时，则为提升成功。
            describe_response: dict = client.describe_db_instances(
                DBInstanceIdentifier=slave_db_Instance_Identifier,
            ).get("DBInstances")[0]
            d1 = datetime.datetime.now
            if describe_response.get("StatusInfos"):
                # StatusInfos：显示同步状态信息, 只有在 slave 为只读副本时才有的字段。
                print(
                    f"waiting aws: {d1().strftime('%Y-%m-%d %H:%M:%S')}", end="\r"
                )
            else:
                # 如果没有 StatusInfos 字段：说明已经脱离只读副本状态，进入提升为主实例的过程/结果。
                # 其中会经过：提升 - 重启 - 备份 - 可调用，三个状态。
                print(
                    f"db: {slave_db_endpoint}, status: {describe_response.get('DBInstanceStatus')}, "
                    f"time: {d1().strftime('%Y-%m-%d %H:%M:%S')}", end="\r")
                if describe_response["DBInstanceStatus"] == "available":
                    set_read_replica_external_master(binlog, log_pos)
                    ic("promote db success")
                    break
            time.sleep(5)
    else:
        ic("get slave binlog err")
        exit()


def check_create_tables(counter=False):
    """
    检查主从表结构，数据量等信息是否相符。通过 `information_schema`.tables 获取实例内所有表，对主从库表创建语句进行比对，得出结果。
    注意："show create table db_name.table_name;" 时，db_name 处应有反引号。

    "information_schema.tables"： 获取此实例内所有表信息
    "show create table `db_name`.table_name;"：显示表创建语句

    :param counter: 是否检查数量，由于 master 是通过 information_schema.tables.TABLE_ROWS 取得数据，所以对于经常改动的表并不准确，
    但是对 master 性能损耗是极低的，反而使用 count(*) 对 db io 损耗极高，且会影响其他 SQL 正常执行，所以在此只对 slave 进行 count(*)。
    :return:
    """
    master_db_cursor = get_mysql_connection(master_db_config)
    slave_db_cursor = get_mysql_connection(slave_db_config)

    master_db_cursor.execute(
        f"select * from information_schema.tables "
        f"where TABLE_SCHEMA not in ('sys','mysql','information_schema','performance_schema');")
    master_db_info_list: list = master_db_cursor.fetchall()

    for master_db_info in master_db_info_list:
        try:
            # 对于同步失败的表进行异常捕获
            slave_db_cursor.execute(
                f"show create table `{master_db_info.get('TABLE_SCHEMA')}`.{master_db_info.get('TABLE_NAME')};")
            slave_db_table_info = slave_db_cursor.fetchone()

            print_info = [
                f"verify success! ",
                f"db：{master_db_info.get('TABLE_SCHEMA')}".ljust(20, " "),
                f"table: {slave_db_table_info.get('Table')}"
            ]
            if counter:
                slave_db_cursor.execute(
                    f"select count(*) as num "
                    f"from {master_db_info.get('TABLE_SCHEMA')}.{master_db_info.get('TABLE_NAME')};")

                slave_db_row_num = slave_db_cursor.fetchone()

                # counter 算法为 slave_num - master_num
                # 结果为负：有少量数据未同步完成；结果为正：极有可能是 master 数据量获取方式问题；结果是0：正常。
                print_info.insert(
                    1, f"verify success! quantity variance: "
                       f"{slave_db_row_num.get('num') - master_db_info.get('TABLE_ROWS')}".ljust(40, " "))

        except Exception as e:
            print(f"table err:{e}, db info: {master_db_info.get('TABLE_SCHEMA')}.{master_db_info.get('TABLE_NAME')}")
        else:
            if master_db_info.get("Create Table") == slave_db_table_info.get("CREATE TABLE"):
                print("\t".join(print_info))
            else:
                print(f"the table variance! table name: {slave_db_table_info.get('Table')}, "
                      f"create table syntax: {slave_db_table_info.get('CREATE TABLE')}")

    master_db_cursor.close()
    slave_db_cursor.close()


def check_master_connections():
    """
    检查 master 是否还有连接存在，如果存在则为迁移不完整。检查信息来自："information_schema.processlist"。
    排除：db="information_schema" 的表，以及系统内账户："root", "system user", "rdsadmin","rdsrepladmin"。

    :return:
    """
    master_db_cursor = get_mysql_connection(master_db_config)
    print(f"connect to {master_db_config}")

    try:
        while True:
            master_db_cursor.execute(
                f"select * from information_schema.processlist  where  "
                f"DB not like DB='information_schema' and "
                f"HOST not like '172.31.4.244%'  and "   # matrix
                f"HOST not like '172.31.16.196%' and "   # cfg
                f"HOST not like '172.31.20.199%' and "   # web1
                f"HOST not like '172.31.15.212%' and "   # web4
                f"HOST not like '172.31.26.145%' and "   # web5
                f"USER not in ('root', 'system user', 'rdsadmin','rdsrepladmin');")

            master_db_process_info = master_db_cursor.fetchall()

            if master_db_process_info:
                for master_db_process in master_db_process_info:
                    print(master_db_process)
                time.sleep(1)
    except KeyboardInterrupt:
        master_db_cursor.close()
        print("\ncheck conn stop")


def check_sync_status(conn_obj: tuple = False, time_sleep: float = 1):
    """
    检查 master 与 slave 同步状态，作为是否开始迁移提供的重要依据。
    conn_obj：复用 migrate_db 连接，否则只检查同步状态。

    :sleeped_time: 停止的最大秒数, 默认为2秒，否则会影响业务。
    :param conn_obj: (master_cursor, slave_cursor)
    :param time_sleep:
    :return: True|False
    """
    if not conn_obj:
        master_db_cursor = get_mysql_connection(master_db_config)
        slave_db_cursor = get_mysql_connection(slave_db_config)
    else:
        master_db_cursor, slave_db_cursor = conn_obj

    # sleeped_time：停止的最大秒数，否则会影响业务。
    sleeped_time = 0
    while True:
        master_db_cursor.execute("show master status;")
        master_sync_status: dict = master_db_cursor.fetchone()

        slave_db_cursor.execute("show slave status;")
        slave_sync_status: dict = slave_db_cursor.fetchone()

        # 获取 master 与 slave binlog 位置及状态。
        master_binlog, master_pos = master_sync_status.get("File"), master_sync_status.get("Position")
        slave_binlog, slave_pos = slave_sync_status.get("Master_Log_File"), slave_sync_status.get("Exec_Master_Log_Pos")
        # ic 略
        ic(master_binlog, type(master_binlog), master_pos, type(master_pos))
        ic(slave_binlog, slave_pos)

        if master_binlog != slave_binlog:
            # binlog 不相符时持续等待。
            ic("waiting slave connect to master: 1s")
            sleeped_time += time_sleep
            time.sleep(time_sleep)
        else:
            # 断开所有连接后，数据完全同步成功
            ic(f"slave connect to master success: \n binlog_file: {slave_binlog}, binlog_pos: {slave_pos}")
            return True

        if time_sleep != 1:
            # time_sleep 默认为 1，如果time_sleep!=1,即处于migrate_db状态，且不能关闭连接进行后续操作。
            if sleeped_time > 2:
                print(f"binlog sync failed, please check sync status! waite time {sleeped_time}s")
                return False
        else:
            # 否则视为只检查binlog同步：最多等待20秒。
            if sleeped_time > 20:
                master_db_cursor.close()
                slave_db_cursor.close()
                print(f"binlog sync failed, please check sync status! waite time {sleeped_time}s")
                return False


def select_db_version():
    """
    检查通过代理查询当前数据库版本信息，作为迁移成功的重要依据。
    :return:
    """
    master_db_cursor = get_mysql_connection(master_proxysql_config)
    master_db_cursor.execute(f"select version();")
    db_version = master_db_cursor.fetchone()
    master_db_cursor.close()
    print(f"The version connected by proxy: {db_version}")
    return db_version


def reset_db(admin_proxysql_cursor=False, migrate_database=False):
    """
    重置 ProxySQL 连接配置。

    :param admin_proxysql_cursor: 复用管理接口连接。
    :param migrate_database: 是否只修改 ProxySQL 中的 endpoint，否则需要判断 ProxySQL 中是否存在 slave 等信息进行添加操作。
    :return:
    """
    admin_proxysql_cursor = admin_proxysql_cursor if \
        admin_proxysql_cursor else get_mysql_connection(admin_proxysql_config)

    if not migrate_database:
        admin_proxysql_cursor.execute(f"select hostgroup_id from mysql_servers where hostname='{slave_db_endpoint}';")
        slave_host_group_id = admin_proxysql_cursor.fetchone()
        print(slave_host_group_id)

        if not slave_host_group_id:
            # 不存在 slave 信息进行添加操作。
            print(f"not found slave host_group_id: {slave_host_group_id}")
            admin_proxysql_cursor.execute(
                f"select hostgroup_id from mysql_servers where hostname='{master_db_endpoint}';")

            slave_host_group_id = admin_proxysql_cursor.fetchone()
            slave_host_group_id = slave_host_group_id.get("hostgroup_id")
            print(slave_host_group_id)

            if slave_host_group_id == 0 or slave_host_group_id:
                # hostgroup_id 为 0 或 不为空，防止误判断。
                admin_proxysql_cursor.execute(
                    f"insert into mysql_servers (hostgroup_id,hostname,port,weight) "
                    f"values ({slave_host_group_id}, '{slave_db_endpoint}', {slave_db_port}, 0);"
                )
    proxysql_reset_query_list = [
        f"update mysql_servers set weight=0 where hostname='{slave_db_endpoint}'",
        f"update mysql_servers set weight=1 where hostname='{master_db_endpoint}'",
        f"update mysql_servers set status='ONLINE' where hostname='{master_db_endpoint}'",
        f"update mysql_servers set status='ONLINE' where hostname='{slave_db_endpoint}'",
        "save mysql servers to disk;", "load  mysql servers to runtime;"
    ]
    for reset_query in proxysql_reset_query_list:
        try:
            # 恢复 ProxySQL 原配置。
            admin_proxysql_cursor.execute(reset_query)
            pass
        except Exception as e:
            print(e)
            ic(f"reset proxysql error: {reset_query}")
        else:
            ic(f"reset proxysql  success: {reset_query}")
    print(select_db_version())
    admin_proxysql_cursor.close()


def rds_kill_conn(kill_sql):
    """
    kill master process，默认 kill 除 binlog、rdsadmin、rdsrepladmin 和 root 外的所有连接。

    rds_kill：结束与 MySQL 服务器的连接。采用官方存储过程。
        https://docs.aws.amazon.com/zh_cn/AmazonRDS/latest/UserGuide/mysql_rds_kill.html

    :param kill_sql:
    :return:
    """
    master_db_cursor = get_mysql_connection(master_db_config)

    if not kill_sql:
        kill_sql = f"select ID,USER,HOST,DB,COMMAND,INFO from information_schema.processlist where " \
                   f"command not in ('Binlog Dump') " \
                   f" and User not in ('rdsadmin','rdsrepladmin', 'root');"

    master_db_cursor.execute(kill_sql)
    kill_query_list: list = master_db_cursor.fetchall()

    if kill_query_list:
        for kill_query_data in kill_query_list:

            kill_id = kill_query_data.get("ID")
            kill_query = f"CALL mysql.rds_kill({kill_id});"
            print(kill_query, kill_query_data)

            try:
                master_db_cursor.execute(kill_query)
                pass
            except Exception as e:
                print(str(e))
                print(f"kill error: {kill_query}")
            else:
                ic(f"kill success: {kill_query}")
    if kill_sql:
        # kill 后打印出所有余下连接。
        master_db_cursor.execute("select * from information_schema.processlist")
        master_process_list = master_db_cursor.fetchall()
        for process in master_process_list:
            print(process)
    master_db_cursor.close()


def each_exec_sql(cursor_obj, sql_list=None):
    """
    循环执行传入 SQL
    :param cursor_obj: 复用连接对象
    :param sql_list: 需要执行的 SQL
    :return:
    """
    for sql in sql_list:
        try:
            cursor_obj.execute(sql)
            pass
        except Exception as e:
            print(e)
            ic(f"sql error: {sql}")
        else:
            ic(f"sql update success: {sql}")


def migrate_db(migrate_proxy=False):
    """
    迁移/修改 ProxySQL，是无缝迁移核心部分。
    master_db_cursor：确认 master binlog 位置。
    slave_db_cursor： 确认 slave binlog 位置，以此判断双方同步状态。
    admin_proxysql_cursor：如果上述 binlog 相同，则为完全同步状态，可以立即切换 proxysql db。

    :param migrate_proxy: 是否仅迁移 ProxySQL，无需 kill 连接等操作。
    :return:
    """
    master_db_cursor = get_mysql_connection(master_db_config)
    slave_db_cursor = get_mysql_connection(slave_db_config)
    admin_proxysql_cursor = get_mysql_connection(admin_proxysql_config)

    # 判断 ProxySQL 中是否存在 slave endpoint 信息，如果不存在则写入。
    admin_proxysql_cursor.execute(f"select hostgroup_id from mysql_servers where hostname='{slave_db_endpoint}';")
    slave_host_group_info: dict = admin_proxysql_cursor.fetchone()

    if slave_host_group_info is None:

        # 查询 master hostgroup_id，作为 slave 的 hostgroup_id。如果不存在则退出。
        # 如果有多个 master 信息，则以第一个为准（此处应该以 hostgroup_id 以大小来排序一下）。
        admin_proxysql_cursor.execute(f"select hostgroup_id from mysql_servers where hostname='{master_db_endpoint}';")
        master_host_group_info = admin_proxysql_cursor.fetchone()

        if master_host_group_info is not None:
            slave_host_group_id = master_host_group_info.get("hostgroup_id")
            print(f"write slave host group id: {slave_host_group_id}")

            admin_proxysql_cursor.execute(
                f"insert into mysql_servers (hostgroup_id,hostname,port,weight) "
                f"values ({slave_host_group_id}, '{slave_db_endpoint}', {slave_db_port}, 0);"
            )
        else:
            # 找不到 master hostgroup_id，脚本退出。
            print("master host group id not found!")
            print("script exit")
            exit(1)

    online_backend = [
        f"update mysql_servers set status='ONLINE' where hostname='{slave_db_endpoint}'",
        f"update mysql_servers set weight=1 where hostname='{slave_db_endpoint}'",
        "save mysql servers to disk;", "load  mysql servers to runtime;"
    ]

    offline_backend = [
        f"update mysql_servers set status='OFFLINE_SOFT' where hostname='{master_db_endpoint}'",
        f"update mysql_servers set status='OFFLINE_SOFT' where hostname='{slave_db_endpoint}'",
        f"update mysql_servers set weight=0 where hostname='{master_db_endpoint}'",
        f"update mysql_servers set weight=0 where hostname='{slave_db_endpoint}'",
        "save mysql servers to disk;", "load  mysql servers to runtime;"
    ]

    change_options = [
        f"UPDATE global_variables SET variable_value=30  WHERE variable_name='mysql-connect_retries_on_failure';",
        f"UPDATE global_variables SET variable_value=2   WHERE variable_name='mysql-query_retries_on_failure';",
        f"UPDATE global_variables SET variable_value=500 WHERE variable_name='mysql-connect_retries_delay';",
        f"UPDATE global_variables SET variable_value=4096 WHERE variable_name='mysql-max_connections';",
        f"UPDATE mysql_servers SET max_connections =500  WHERE hostname = '{master_db_endpoint}';",
        f"UPDATE mysql_servers SET max_connections =500  WHERE hostname = '{slave_db_endpoint}';",
        "save mysql servers to disk;", "load  mysql servers to runtime;"
    ]

    kill_process = f"select ID,USER,HOST,DB,COMMAND,INFO from information_schema.processlist where " \
                   f"command not in ('Binlog Dump') " \
                   f" and User not in ('rdsadmin') " \
                   f" and User not in ('rdsrepladmin') " \
                   f" and USER not in ('root');"
    stop_replication_sql = [
        "CALL mysql.rds_stop_replication;",
        "CALL mysql.rds_reset_external_master;"
    ]

    # master_db_cursor.execute(kill_process)
    # kill_query_list = master_db_cursor.fetchall()
    # each_exec_sql(master_db_cursor, kill_query_list)

    # 修改 ProxySQL 重试选项，离线 master 与 slave，使其不再接受新请求。
    each_exec_sql(admin_proxysql_cursor, change_options)
    each_exec_sql(admin_proxysql_cursor, offline_backend)

    if not migrate_proxy:
        # 如果不只修改 ProxySQL，则要先 kill 所有连接，等待同步完成。
        rds_kill_conn(kill_process)
        binlog_finish = check_sync_status((master_db_cursor, slave_db_cursor), time_sleep=0.1)
    else:
        # 测试用，无需等待同步完成。
        binlog_finish = True

    if binlog_finish:
        # 同步完成，停止主从复制，上线 slave。
        each_exec_sql(slave_db_cursor, stop_replication_sql)
        each_exec_sql(admin_proxysql_cursor, online_backend)
    else:
        # 等待2秒后未同步完成，则恢复原配置，手工检查异常状态。
        reset_db(admin_proxysql_cursor, migrate_database=True)

    print(f"master_proxy: {master_proxysql_endpoint}\nversion: {select_db_version()}")

    admin_proxysql_cursor.close()
    master_db_cursor.close()


def main():
    """
    parser: 非常好用的内置参数库，写脚本必备技能。
        https://blog.xiayf.cn/2013/03/30/argparse/
    :return:
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-r", dest="reset", action='store_true', help="reset ProxySQL master and slave endpoint")
    parser.add_argument("-m", dest="migrate", action='store_true', help="migrate proxysql master to slave")
    parser.add_argument("-p", dest="promote", action='store_true', help="promote replica instance")
    parser.add_argument("-v", dest="version", action='store_true', help="check ProxySQL version")
    parser.add_argument("-c", dest="check_conn", action='store_true', help="check master conn")
    parser.add_argument("-t", dest="check_table", action='store_true',
                        help="check master and slave create table syntax")
    parser.add_argument("--counter", dest="count", action="store_true",
                        required=False, help='Check the number of rows must be use with -t')
    parser.add_argument("--proxysql", dest="migrate_proxy", action="store_true",
                        required=False, help='only migrate proxysql must be use with -m')
    args = parser.parse_args()

    if args.migrate:
        print("migrate proxysql master to slave")
        migrate_db(args.migrate_proxy)

    elif args.promote:
        print("promote replica instance")
        print(f"master db: {master_db_endpoint}")
        print(f"slave db: {slave_db_endpoint}")
        promote_read_replica_db()

    elif args.reset:
        print("reset proxysql")
        reset_db()

    elif args.check_table:
        print("check slave table")
        check_create_tables(args.count)

    elif args.version:
        select_db_version()

    elif args.check_conn:
        check_master_connections()


if __name__ == '__main__':
    main()
