## php-rdkafka 扩展安装
php有两种方式调用kafka
### 1、php-rdkafka
文档地址：https://arnaud-lb.github.io/php-rdkafka/phpdoc/book.rdkafka.html
rdkafka安装需要依赖 librdkafka 所以我们需要先安装 librdkafka
下载地址: http://pecl.php.net/package/rdkafka

```bash
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka
./configure
make && make install
```

安装php-rdkafka扩展
```bash
git clone https://github.com/arnaud-lb/php-rdkafka.git
cd php-rdkafka
phpize
./configure --with-php-config=/usr/local/php7.0/bin/php-config
make && make install
```

然后在php.ini写入
`extension = rdkafka.so`
### 2、kafka-php 扩展包
文档地址：https://github.com/weiboad/kafka-php （最后更新时间 2020 年，已经关闭公共提交了）

### 3、简单示例
生成者
```php
<?php

$rk = new RdKafka\Producer();
$rk->setLogLevel(LOG_DEBUG);
$rk->addBrokers("192.168.2.152");

$topic = $rk->newTopic("shop");

for ($i = 0; $i < 10; $i++) {
    $topic->produce(RD_KAFKA_PARTITION_UA, 0, "发送信息： $i");
    $rk->poll(0);
}

while ($rk->getOutQLen() > 0) {
    $rk->poll(50);
}

?>
```

消费者
```php
<?php

$conf = new RdKafka\Conf();

$conf->set('group.id', 'myConsumerGroup');

$rk = new RdKafka\Consumer($conf);
$rk->addBrokers("192.168.2.150:9092");

$topicConf = new RdKafka\TopicConf();
$topicConf->set('auto.commit.interval.ms', 100);
$topicConf->set('offset.store.method', 'file');
$topicConf->set('offset.store.path', sys_get_temp_dir());
$topicConf->set('auto.offset.reset', 'smallest');

$topic = $rk->newTopic("shop", $topicConf);

// Start consuming partition 0
$topic->consumeStart(0, RD_KAFKA_OFFSET_STORED);

while (true) {
    $message = $topic->consume(0, 120*10000);
    switch ($message->err) {
        case RD_KAFKA_RESP_ERR_NO_ERROR:
        //没有错误打印信息
            var_dump($message);
            break;
        case RD_KAFKA_RESP_ERR__PARTITION_EOF:
            echo "等待接收信息\n";
            break;
        case RD_KAFKA_RESP_ERR__TIMED_OUT:
            echo "超时\n";
            break;
        default:
            throw new \Exception($message->errstr(), $message->err);
            break;
    }
}

?>
```