<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-25 10:29:06
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-11-25 11:21:35
-->

### pushgateway
  1. pushgateway是另一种采用被动推送的方式(而不是exporter主动获取)获取监控数据的插件.
  2. 它可以单独运行在任何节点上的插件(并不一定要在被监控客户端).
  3. 通过用户自定义开发脚本, 把需要监控的数据, 发送给pushgateway, 然后pushgateway再把数据推送给prometheus server.

#### 运行方式
[GitHub官方地址](https://github.com/prometheus/pushgateway)
下载解压后, 直接运行
```bash
[root@server04 down]$ daemonize -c  /data/pushgateway/  /data/pushgateway/pushgatewayUp.sh
[root@server04 down]$ cat /data/prometheus/pushgatewayUp.sh
/data/pushgateway/pushgateway  --web.listen-address="0.0.0.0:9092"
```
