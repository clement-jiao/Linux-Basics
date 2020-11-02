### PostgreSQL 查看数据库，索引，表，表空间大小
#### 一、简介

PostgreSQL 提供了多个系统管理函数来查看表，索引，表空间及数据库的大小，下面详细介绍一下。

#### 二、数据库对象尺寸函数

| 函数名 |  返回类型 | 描述 |
|:---:|:---:|:---:|
|pg_column_size(any) | 	int | 存储一个指定的数值需要的字节数（可能压缩过） |
|pg_database_size(oid)	|bigint|	指定OID的数据库使用的磁盘空间|
|pg_database_size(name)	|bigint|	指定名称的数据库使用的磁盘空间|
|pg_indexes_size(regclass)	|bigint|	关联指定表OID或表名的表索引的使用总磁盘空间|
|pg_relation_size(relation regclass, fork text)	|bigint|	指定OID或名的表或索引，通过指定fork('main', 'fsm' 或'vm')所使用的磁盘空间|
|pg_relation_size(relation regclass)	|bigint|	pg_relation_size(..., 'main')的缩写|
|pg_size_pretty(bigint)	|text|	Converts a size in bytes expressed as a 64-bit integer into a human-readable format with size units|
|pg_size_pretty(numeric)	|text|	把以字节计算的数值转换成一个人类易读的尺寸单位|
|pg_table_size(regclass)	|bigint|	指定表OID或表名的表使用的磁盘空间，除去索引（但是包含TOAST，自由空间映射和可视映射）|
|pg_tablespace_size(oid)	|bigint|	指定OID的表空间使用的磁盘空间|
|pg_tablespace_size(name)	|bigint|	指定名称的表空间使用的磁盘空间|
|pg_total_relation_size(regclass)	|bigint|	指定表OID或表名使用的总磁盘空间，包括所有索引和TOAST数据|

#### 三、实例讲解

##### 3.1 查看存储一个指定的数值需要的字节数
```sql
david=# select pg_column_size(1);
 pg_column_size
----------------
              4
(1 row)

david=# select pg_column_size(10000);
 pg_column_size
----------------
              4
(1 row)

david=# select pg_column_size('david');
 pg_column_size
----------------
              6
(1 row)

david=# select pg_column_size('hello,world');
 pg_column_size
----------------
             12
(1 row)

david=# select pg_column_size('2013-04-18 15:17:21.622885+08');
 pg_column_size
----------------
             30
(1 row)

david=# select pg_column_size('中国');
 pg_column_size
----------------
              7
(1 row)

david=#
```

##### 3.2 查看数据库大小

查看原始数据
```sql
david=# \d test
              Table "public.test"
  Column   |         Type          | Modifiers
-----------+-----------------------+-----------
 id        | integer               |
 name      | character varying(20) |
 gender    | boolean               |
 join_date | date                  |
 dept      | character(4)          |
Indexes:
    "idx_join_date_test" btree (join_date)
    "idx_test" btree (id)

david=# select count(1) from test;
  count
---------
 1835008
(1 row)

david=#
```
查看david 数据库大小
```sql
david=# select pg_database_size('david');
 pg_database_size
------------------
        190534776
(1 row)

david=#
```
查看所有数据库大小
```sql
david=# select pg_database.datname, pg_database_size(pg_database.datname) AS size from pg_database;
  datname  |    size
-----------+-------------
 template0 |     6513156
 postgres  |     6657144
 jboss     |     6521348
 bugs      |     6521348
 david     |   190534776
 BMCV3     | 28147135608
 mydb      |    10990712
 template1 |     6521348
(8 rows)

david=#
```
这样查出来的结果，看上去太长了，不太容易读数。

##### 3.3 以人性化的方式显示大小
```sql
david=# select pg_size_pretty(pg_database_size('david'));
 pg_size_pretty
----------------
 182 MB
(1 row)

david=#
```
##### 3.4 查看单索引大小
```sql
david=# select pg_relation_size('idx_test');
 pg_relation_size
------------------
         41238528
(1 row)

david=# select pg_size_pretty(pg_relation_size('idx_test'));
 pg_size_pretty
----------------
 39 MB
(1 row)

david=#
```
---
```sql
david=# select pg_size_pretty(pg_relation_size('idx_join_date_test'));
 pg_size_pretty
----------------
 39 MB
(1 row)

david=#
```
##### 3.5 查看指定表中所有索引大小
```sql
david=# select pg_indexes_size('test');
 pg_indexes_size
-----------------
        82477056
(1 row)

david=# select pg_size_pretty(pg_indexes_size('test'));
 pg_size_pretty
----------------
 79 MB
(1 row)

david=#
```
idx_test 和idx_join_date_test 两个索引大小加起来差不多等于上面pg_indexes_size() 查询出来的索引大小。

##### 3.6 查看指定schema 里所有的索引大小，按从大到小的顺序排列。
```sql
david=# select * from pg_namespace;
      nspname       | nspowner |               nspacl
--------------------+----------+-------------------------------------
 pg_toast           |       10 |
 pg_temp_1          |       10 |
 pg_toast_temp_1    |       10 |
 pg_catalog         |       10 | {postgres=UC/postgres,=U/postgres}
 information_schema |       10 | {postgres=UC/postgres,=U/postgres}
 public             |       10 | {postgres=UC/postgres,=UC/postgres}
(6 rows)

david=# select indexrelname, pg_size_pretty(pg_relation_size(relid)) from pg_stat_user_indexes where schemaname='public' order by pg_relation_size(relid) desc;
         indexrelname          | pg_size_pretty
-------------------------------+----------------
 idx_join_date_test            | 91 MB
 idx_test                      | 91 MB
 testtable_idx                 | 1424 kB
 city_pkey                     | 256 kB
 city11                        | 256 kB
 countrylanguage_pkey          | 56 kB
 sale_pkey                     | 8192 bytes
 track_pkey                    | 8192 bytes
 tbl_partition_201211_joindate | 8192 bytes
 tbl_partition_201212_joindate | 8192 bytes
 tbl_partition_201301_joindate | 8192 bytes
 tbl_partition_201302_joindate | 8192 bytes
 tbl_partition_201303_joindate | 8192 bytes
 customer_pkey                 | 8192 bytes
 album_pkey                    | 8192 bytes
 item_pkey                     | 8192 bytes
 tbl_partition_201304_joindate | 8192 bytes
 tbl_partition_201307_joindate | 8192 bytes
 tbl_partition_201305_joindate | 0 bytes
 tbl_partition_201306_joindate | 0 bytes
(20 rows)

david=#
```
##### 3.7 查看指定表大小
```sql
david=# select pg_relation_size('test');
 pg_relation_size
------------------
         95748096
(1 row)

david=# select pg_size_pretty(pg_relation_size('test'));
 pg_size_pretty
----------------
 91 MB
(1 row)

david=#
```
使用pg_table_size() 函数查看
```sql
david=# select pg_table_size('test');
 pg_table_size
---------------
      95789056
(1 row)

david=# select pg_size_pretty(pg_table_size('test'));
 pg_size_pretty
----------------
 91 MB
(1 row)

david=#
```
##### 3.8 查看指定表的总大小
```sql
david=# select pg_total_relation_size('test');
 pg_total_relation_size
------------------------
              178266112
(1 row)

david=# select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 170 MB
(1 row)

david=#
```
##### 3.9 查看指定schema 里所有的表大小，按从大到小的顺序排列。
```sql
david=# select relname, pg_size_pretty(pg_relation_size(relid)) from pg_stat_user_tables where schemaname='public' order by pg_relation_size(relid) desc;
            relname            | pg_size_pretty
-------------------------------+----------------
 test                          | 91 MB
 testtable                     | 1424 kB
 city                          | 256 kB
 countrylanguage               | 56 kB
 country                       | 40 kB
 testcount                     | 8192 bytes
 tbl_partition_201302          | 8192 bytes
 tbl_partition_201303          | 8192 bytes
 person                        | 8192 bytes
 customer                      | 8192 bytes
 american_state                | 8192 bytes
 tbl_david                     | 8192 bytes
 emp                           | 8192 bytes
 tbl_partition_201212          | 8192 bytes
 tbl_partition_201304          | 8192 bytes
 tbl_partition_error_join_date | 8192 bytes
 tbl_partition_201211          | 8192 bytes
 album                         | 8192 bytes
 tbl_partition_201307          | 8192 bytes
 tbl_xulie                     | 8192 bytes
 tbl_partition_201301          | 8192 bytes
 sale                          | 8192 bytes
 item                          | 8192 bytes
 track                         | 8192 bytes
 tbl_partition_201306          | 0 bytes
 tbl_partition                 | 0 bytes
 tbl_partition_201305          | 0 bytes
 person2                       | 0 bytes
(28 rows)

david=#
```
##### 3.10 查看表空间大小
```sql
david=# select spcname from pg_tablespace;
  spcname
------------
 pg_default
 pg_global
(2 rows)

david=# select pg_tablespace_size('pg_default');
 pg_tablespace_size
--------------------
        28381579760
(1 row)

david=# select pg_size_pretty(pg_tablespace_size('pg_default'));
 pg_size_pretty
----------------
 26 GB
(1 row)

david=#
```
另一种查看方法：
```sql
david=# select pg_tablespace_size('pg_default')/1024/1024 as "SIZE M";
 SIZE M
--------
  27066
(1 row)

david=# select pg_tablespace_size('pg_default')/1024/1024/1024 as "SIZE G";
 SIZE G
--------
     26
(1 row)

david=#
```
