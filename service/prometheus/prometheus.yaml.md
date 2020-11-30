<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-30 15:09:15
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-11-30 17:39:27
-->
### prometheus.yaml 配置

##### 在prometheus 添加告警规则
```yaml
# cat /etc/prometheus/rules/node_alerts.yaml
groups:
- name: node_alerts
  rules:
  - alert: HighNodeCPU
    expr: instance:node_cpu:avg_rate5m > 4
    for: 2m
    labels:
      serverity: warning
    annotations:
      summary: High Node CPU for 1 Hour
      console: Thank you Test
```

##### rules 持久化查询示例:
```yaml
goups:
- name: node_rules
  rules:
    - record: instance:node_cpu:avg_rate5m  # 查询语句
    expr: 100 - avg(irate(node_cpu_seconds_total{job="node", mode="idle"}[5m])) by (instance) * 100
    - record: instance:node_memory_usage:percentage
    expr: (node_memory_MemTotal_bytes - (node_memory_MemFree_bytes + node_memory_Cached_bytes + node_memory_Buffers_bytes)) / node_memory_MemTotal_bytes * 100
    - record: instance:root:node_filesystem_usage:percentage
    expr: (node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100
```
##### 基于文件的服务发现
```yaml
# cat /etc/prometheus/prometheus.yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'nodes'
    file_sd_configs:
      - files:
        - targets/nodes/*.json    #
        refresh_interval: 5m     # 刷新时间

  - job_name: dockers
    file_sd_configs:
      - files:
        - targets/dockers/*.json
        refresh_interval: 5m

# cat /etc/prometheus/targets/nodes/node.json
[{
  "targets":[
    "192.168.11.174:9100",
    "192.168.11.175:9100",
    "192.168.11.176:9100",
  ]
}]
# cat /etc/prometheus/targets/dockers/docker.json
[{
  "targets":[
    "192.168.11.174:8080",
    "192.168.11.175:8080",
    "192.168.11.176:8080",
  ],
  "labels":{
    "datacenter":"nj",
  }
}]
# 通过promtool检查配置文件
[deploy@localhost ~]$ promtool check config /etc/prometheus/prometheus.yaml
# 配置文件检查成功后 通过发送信号使prometheus重新加载配置文件
[deploy@localhost ~]$ kill -HUP [prometheus pid]
```

##### 基于 DNS 的服务发现
DNS 服务发现依赖于查询A、AAAA或SRV DNS记录.
```yaml
# 基于 SRV 记录发现
# 注意: _prometheus为服务名称, _tcp为协议, xiongdi.cn为域名
# 需要在 DNS 服务端进行 SRV 信息设置
scrape_configs:
  - job_name: "webapp"
  dns_sd_configs:
    - names: ["_prometheus._tcp.xiongdi.cn"]



# 基于 A 记录发现
# 注意: _prometheus为服务名称, _tcp为协议, xiongdi.cn为域名
# 需要在 DNS 服务端进行 SRV 信息设置
scrape_configs:
  - job_name: "webapp"
  dns_sd_configs:
    - names: ["c720172.xiongdi.cn]
      type: A
      port: 9100

# 通过promtool检查配置文件
[deploy@localhost ~]$ promtool check config /etc/prometheus/prometheus.yaml
# 配置文件检查成功后 通过发送信号使prometheus重新加载配置文件
[deploy@localhost ~]$ kill -HUP [prometheus pid]
```
