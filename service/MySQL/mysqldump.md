## mysqldump

### 安装
yum repository
https://dev.mysql.com/downloads/repo/yum/

### 备份单个库
mysqldump -u root -h 127.0.0.1 -p --single-transaction --source-data=2 --databases owh > owh.sql

### 备份某个表
mysqldump -u root -h 127.0.0.1 -p --single-transaction --source-data=2 --databases owh --tables cms_applications > cms.sql

### 导出db1、db2两个数据库的所有数据
mysqldump -uroot -proot --databases db1 db2 >/tmp/user.sql

### 条件导出，导出db1表a1中id=1的数据
如果多个表的条件相同可以一次性导出多个表
mysqldump -uroot -proot --databases db1 --tables a1 --where='id=1'  >/tmp/a1.sql

### mysqldump 详解
https://www.cnblogs.com/chenmh/p/5300370.html

### MyISAM 转 InnoDB
思路：
1）导出旧数据库表结构
2）修改引擎为innodb
3）导入旧数据库表结构到新数据库
4）非工作时间段停应用、导出旧数据库数据（不导表结构）
5）导入旧数据库数据（sql_mode调整）
6）调整新数据库编码为utf8mb4
https://www.toutiao.com/article/6767935333582504451/
