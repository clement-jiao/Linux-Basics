## redis-shake

官网：https://github.com/alibaba/RedisShake
快速开始：https://github.com/alibaba/RedisShake/wiki/快速开始：数据迁移#单机到单机a-b


RedisShake 是一个用于在两个 Redis 之间同步数据的工具，满足非常灵活的同步与迁移需求。

支持解析、恢复、备份与同步四个功能：
恢复（restore）：将 RDB 文件恢复到目的 Redis 数据库。

备份（dump）：将源 Redis 的全量数据通过 RDB 文件备份。

解析（decode）：读取 RDB 文件，并以 JSON 格式解析存储。

同步（sync）：支持源 Redis 和目的 Redis 的数据同步，支持全量和增量数据的迁移。

同步（rump）：支持源 Redis 和目的 Redis 的数据同步，仅支持全量迁移。

### 参考


使用redis-shake备份Redis实例

https://help.aliyun.com/document_detail/119991.html



redis-shake数据同步&迁移工具

https://developer.aliyun.com/article/691794



redis如何使用redis-shake迁移数据

https://www.yisu.com/zixun/4298.html



两个Redis集群 如何平滑数据迁移

https://developer.aliyun.com/article/726005

作者：Bogon
链接：http://events.jianshu.io/p/18cf795463f9
来源：简书
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。