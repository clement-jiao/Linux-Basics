<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-25 11:46:44
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-11-25 11:57:42
-->


### node-exporter

#### 运行方式
[GitHub官方地址](https://github.com)
**1. 下载解压后直接运行**
**2. 封装service**
  - 添加用户prometheus:
    ```bash useradd --no-create-home --shell /bin/false node_exporter```
  - 创建相关目录
    ```bash
    mkdir /etc/prometheus
    mkdir /var/lib/prometheus
    ```
  - 更改目录权限
    ```bash chown node_exporter:node_exporter /etc/node_exporter ```
  - 配置node_exporter service，端口为9101
    **vim /etc/systemd/system/node-exporter.service**
    ```bash
    [root@server04 down]$ vim /etc/systemd/system/node-exporter.service
    [root@server04 down]$ cat /etc/systemd/system/node-exporter.service
    [Unit]
    Description=Prometheus Node Exporter
    After=network.target
    [Service]
    User=node_exporter
    Group=node_exporter
    ExecStart=/data/node_exporter/node_exporter --web.listen:0.0.0.0:9101
    [Install]
    WantedBy=multi-user.target
    ```
  - 加载systemd服务 & 启动
    ```bash
    # 加载
    systemctl daemon-reload
    # 开机启动
    systemctl enable node-exporter.service
    # 启动
    systemctl start node-exporter
    # 启动并开机自启二合一
    systemctl --now start node-exporter.service
    # 查看状态
    systemctl status node-exporter.service
    ```
#### 注意事项:
  - **修改ExecStart和User**
