### ELK
[toc]
#### 一、 elk介绍
[官网演示地址](https://demo.elastic.co/)

ELK = Elasticsearch, Logstash, Kibana 是一套实时数据收集，存储，索引，检索，统计分析及可视化的解决方案。
最新版本已经改名为Elastic Stack，并新增了Beats项目。
#### 二、 日志收集分类
```html
代理层： nginx，haproxy
web层： nginx，Tomcat
数据库层：mysql，redis，MongoDB，elasticsearch
操作系统层：source，message
```
#### 三、安装部署elk
##### 3.1 rpm包下载
- 官网地址：https://www.elastic.co/guide/index.html
- 官方下载地址：https://www.elastic.co/cn/downloads/past-releases#elasticsearch
- 清华源下载地址:https://mirrors.tuna.tsinghua.edu.cn/elasticstack/yum/elastic-7.x/7.5.2/elasticsearch-7.5.2-x86_64.rpm
)
- kibana下载地址(建议与es同版本):https://artifacts.elastic.co/downloads/kibana/kibana-7.5.2-linux-x86_64.tar.gz
- filebeat下载地址：https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.5.2-x86_64.rpm
- logstash下载地址：https://artifacts.elastic.co/downloads/logstash/logstash-7.52.rpm
##### 3.2 安装java
```bash
[root@elk-6-8-6 ~]$ yum install -y java-1.8.0-openjdk.x86_64
[root@localhost ~]$ java -version
java version "1.8.0_231"
Java(TM) SE Runtime Environment (build 1.8.0_231-b11)
Java HotSpot(TM) 64-Bit Server VM (build 25.231-b11, mixed mode)
```
##### 3.3 更新时间: **必要项**
```bash
[root@localhost ~]$ yum install ntpdate.x86_64 -y
[root@localhost ~]$ ntpdate time1.aliyun.com
```
#### 3.3.1 注意nginx、filebeat、elasticsearch时区问题！！！

**如果 nginx 时区与 filebeat 或 es 时区不一致，极有可能导致日志收集失败或错误等问题！！**

**正确做法应是将所有时区统一设置成 Asia/Shanghai 这个时区**

##### 3.4 安装 elastic 7.5.2
```bash
# [root@es001 ~]$ yum install -y elasticsearch-7.5.2-x86_64.rpm
grep "^[a-Z]" /etc/elasticsearch/elasticsearch.yml
# 启动必要配置
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 192.168.11.108
http.port: 9200
cluster.initial_master_nodes: ["node-1"]

# 注意关闭Firewalls和seLinux
# systemctl restart elasticsearch
# 启动后和查看 9200 端口
```

##### 3.##### 4.1 相关配置目录及配置文件
```
[root@localhost ~]# rpm -qc elasticsearch
/etc/elasticsearch/elasticsearch.yml
/etc/elasticsearch/jvm.options
/etc/elasticsearch/log4j2.properties
/etc/elasticsearch/role_mapping.yml
/etc/elasticsearch/roles.yml
/etc/elasticsearch/users
/etc/elasticsearch/users_roles
/etc/init.d/elasticsearch
/etc/sysconfig/elasticsearch
/usr/lib/sysctl.d/elasticsearch.conf
/usr/lib/systemd/system/elasticsearch.service
```
##### 3.5 启动失败报错
待补充

##### 3.6 检查是否启动成功
查看端口
```bash
[root@localhost ~]$ ss -tnl |grep 9200
LISTEN  0  128 [::ffff:192.168.11.108]:9200   [::]:*   users:(("java",pid=20170,fd=244))
```

访问地址：http://192.168.11.108:9200/
```json
{
  "name" : "node-1",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "s2Vb0avaTuKgo5mlViL5IA",
  "version" : {
    "number" : "7.5.2",
    "build_flavor" : "default",
    "build_type" : "rpm",
    "build_hash" : "8bec50e1e0ad29dad5653712cf3bb580cd1afcdf",
    "build_date" : "2020-01-15T12:11:5#### 2.313576Z",
    "build_snapshot" : false,
    "lucene_version" : "8.##### 3.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```
##### 3.7 服务模式安装配置 es-head插件
##### 3.7.1 插件官方地址
[首页有帮助文档](https://github.com/mobz/elasticsearch-head)
##### 3.7.2 使用docker部署 elasticsearch-head
```bash
docker pull alivv/elasticsearch-head
docker run --name es-head -p 9100:9100 -dit alivv/elasticsearch-head
```
##### 3.7.3 使用nodeJS编译安装
下载安装
```bash
yum install -y nodejs npm openssl screen
node -v
npm -v
npm install -g cnpm --registry=https://registry.npm.taobao.org
cd /opt/
git clone git://github.com/mobz/elasticsearch-head.git
cd elasticsearch-head
cnpm install
screen -S es-head # 创建窗口
cnpm run start
ctrl+a+d # 保留至后台并退出
```

##### 3.7.4 修改ES配置文件支持跨域
官方说明：https://www.elastic.co/guide/en/elasticsearch/reference/7.5/modules-http.html

配置参数：
```yaml
http.cors.enabled:true
http.cors.allow-origin:"*"
```

##### 3.7.5 谷歌浏览器插件形式安装 es-head
使用服务模式安装es-head插件过程比较繁琐，网络不好时还会经常卡主
幸运的是es-head插件官方还提供了另外一种更简便的方式，就是 Google Chrome的插件
优势如下：
  1. 免安装
  #### 2. 只要浏览器和服务器可以通行就能使用

##### 3.8 安装配置 kibana
```bash
[root@localhost ~]$ yum install -y kibana-##### 4.6.6-i686.rpm
[root@localhost ~]$ rpm -qc kibana
/etc/kibana/kibana.yml
[root@es001 ~]$ grep "^[a-Z]" /etc/kibana/kibana.yml
# 启动必要配置
server.port: 5601
server.host: "192.168.11.108"
server.name: "es001"
elasticsearch.hosts: ["http://192.168.11.108:9200"]
kibana.index: ".kibana"
i18n.locale: "zh-CN"
[root@es001 ~]$
```
##### 3.9 安装filebeat和logstash
```bash
[root@es001 elk]$ yum install -y filebeat-7.5.2-x86_64.rpm logstash-7.52.rpm
```
##### 3.9.1 相关配置目录及配置文件
```bash
# filebeat
[root@es001 elk]$ rpm -qc filebeat
/etc/filebeat/filebeat.yml
/etc/filebeat/modules.d/...

# logstash
[root@es001 elk]$ rpm -qc logstash
/etc/logstash/jvm.options
/etc/logstash/log4j2.properties
/etc/logstash/logstash-sample.conf
/etc/logstash/logstash.yml
/etc/logstash/pipelines.yml
/etc/logstash/startup.options
```

##### 3.9.2 filebeat 启动必要配置
```yaml
filebeat.inputs:
- type: log
  enabled: true
  json.keys_under_root: true    # json格式日志必要配置
  json.add_error_key: true      # json格式日志必要配置
  json.message_key: log         # json格式日志必要配置
  paths:
    - /docker/nginx/log/1.access.log
    - /docker/nginx/log/2.access.log
    - /docker/nginx/log/3.access.log
    - /docker/nginx/log/4.access.log
    - /docker/nginx/log/uat.access.log
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
  host: "192.168.11.108:5601"
output.elasticsearch:
  hosts: ["192.168.11.108:9200"]
  index: "nginx-%{[agent.version]}-%{+yyyy.MM.dd}"      # 修改索引名必要配置，没生效

setup.template.name: "nginx"                            # 修改索引名必要配置，没生效
setup.template.pattern: "nginx-*"                       # 修改索引名必要配置，没生效
setup.template.enabled: false                           # 修改索引名必要配置，没生效
setup.template.overwrite: true                          # 修改索引名必要配置，没生效
```

##### 3.10 docker安装elk
```yaml
# 未验证
version: '##### 3.7'
services:
  elasticsearch:
    image: elasticsearch:v1
    container_name: elasticsearch
    environment:
      - cluster.name=docker-cluster
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms8g -Xmx8g"
      - "discovery.zen.ping.unicast.hosts=elasticsearch"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - /data/docker_es_data:/usr/share/elasticsearch/data
    ports:
      - 19200:9200
    networks:
      - essnet
  elasticsearch-head:
    image: elasticsearch-head:v1
    container_name: elasticsearch-head
    ports:
      - 19100:9100
    networks:
      - esnet
  kibana:
    image: kibana:v1
    container_name: kibana
    environment:
      - ELASTICSEARCH_URL="http://elasticsearch:9200"
      - kibana.index=".kibana"
    ports:
      - 15601:5601
    networks:
      - esnet
  logstash:
    image: logstash:v1
    container_name: logstash
    environment:
      - ELASTICSEARCH_URL="http://elasticsearch:9200"
    ports:
      - 16379:6379
    networks:
      - esnet
networks:
  esnet
```

#### 四、使用filebeat配置日志收集
##### 4.1 收集nginx日志
##### 4.1.1 安装docker和ab工具
```bash
[root@es001 ~]$ yum install -y docker-ce httpd-tools
```
##### 4.1.2 docker-compose安装nginx
```yaml
version: '##### 3.7'
services:
  nginx001:
    image: nginx:latest
    container_name: nginx001
    ports:
      - "8081:80"
    volumes:
      - /docker/nginx:/etc/nginx
      - /workspace:/workspace
  nginx002:
    image: nginx:latest
    container_name: nginx002
    ports:
      - "8082:80"
    volumes:
      - /docker/nginx:/etc/nginx
      - /workspace:/workspace
  nginx003:
    image: nginx:latest
    container_name: nginx003
    ports:
      - "8083:80"
    volumes:
      - /docker/nginx:/etc/nginx
      - /workspace:/workspace
  nginx004:
    image: nginx:latest
    container_name: nginx004
    ports:
      - "8084:80"
    volumes:
      - /docker/nginx:/etc/nginx
      - /workspace:/workspace
```
##### 4.1.3 nginx 配置文件
```conf
server {
    listen       80;
    server_name  localhost,192.168.11.108;
    client_max_body_size 100M;

    location /1 {
        # 解决同配置文件，同日志路径问题
        access_log  /etc/nginx/log/1.access.log  main;
        root   /workspace/;
        index  index.html index.htm;
    }
    location /2 {
        access_log  /etc/nginx/log/2.access.log  main;
        root   /workspace/;
        index  index.html index.htm;
    }
    location /3 {
        access_log  /etc/nginx/log/3.access.log  main;
        root   /workspace/;
        index  index.html index.htm;
    }
    location /4 {
        access_log  /etc/nginx/log/4.access.log  main;
        root   /workspace/;
        index  index.html index.htm;
    }
}
```
##### 4.1.4 使用ab创建日志数据
```bash
[root@es001 ~]$ ab -n 100 -c 100 http://192.168.11.108:8081/1/index.html
[root@es001 ~]$ ab -n 100 -c 100 http://192.168.11.108:8082/2/index.html
[root@es001 ~]$ ab -n 100 -c 100 http://192.168.11.108:8083/3/index.html
[root@es001 ~]$ ab -n 100 -c 100 http://192.168.11.108:8084/4/index.html
```
##### 4.1.5 收集多个日志并分类创建索引
filebeat配置
```yaml
filebeat.inputs:
- type: log
  enabled: true
  json.keys_under_root: true    # json格式日志7.5版本必要配置
  json.add_error_key: true      # json格式日志7.5版本必要配置
  json.message_key: log         # json格式日志7.5版本必要配置
  tags: ["access"]
  paths:
    - /docker/nginx/log/access.log
- type: log
  enabled: true
  json.keys_under_root: true    # json格式日志7.5版本必要配置
  json.add_error_key: true      # json格式日志7.5版本必要配置
  json.message_key: log         # json格式日志7.5版本必要配置
  tags: ["error"]
  paths:
    - /docker/nginx/log/error.log
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
  host: "192.168.11.108:5601"
output.elasticsearch:
  hosts: ["192.168.11.108:9200"]
  index: "nginx-%{[agent.version]}-%{+yyyy.MM.dd}"      # 修改索引名7.5版本必要配置，没生效
  indices:
    - index: "nginx_access-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "access"                                  # 也可以写其他键名与内容："remoute_ip":"192.168.11.108"
    - index: "nginx_error-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "error"
setup.template.name: "nginx"                            # 修改索引名7.5版本必要配置，没生效
setup.template.pattern: "nginx-*"                       # 修改索引名7.5版本必要配置，没生效
setup.template.enabled: false                           # 修改索引名7.5版本必要配置，没生效
setup.template.overwrite: true                          # 修改索引名7.5版本必要配置，没生效
setup.template.settings:
  index.number_of_shards: 3
```
