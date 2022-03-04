proxysql_ip = '172.16.0.2'

# master: masterdb.aaaaaaaaaa.us-west-1.rds.amazonaws.com
#  slave:  slavedb.aaaaaaaaaa.us-west-1.rds.amazonaws.com

region_id = "aaaaaaaaaa"
region_name = "us-east-1"

master_db_port = 3306
master_db_username = "masterdb_root"
master_db_password = "你瞅啥?"
master_db_Instance_Identifier = "masterdb"

slave_db_port = 3306
slave_db_username = "slavedb_root"
slave_db_password = "这玩意儿是你能看的吗?"
slave_db_Instance_Identifier = "slavedb"

master_proxysql_port = 3306
master_proxysql_username = "master_user"
master_proxysql_password = "听爸爸一句劝!"
master_proxysql_endpoint = proxysql_ip

admin_proxysql_port = 6032
admin_proxysql_username = "proxysql_admin"
admin_proxysql_password = "这玩意儿不是你能看的孩子."
admin_proxysql_endpoint = proxysql_ip

aws_access_key_id = "乖,听话,听话就给你看."
aws_secret_access_key = "听话,咱不看!"
