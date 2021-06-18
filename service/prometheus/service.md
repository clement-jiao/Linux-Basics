[toc]

## Prometheus的守护进程

### 系统守护进程

> 修改完成记得 systemctl daemon-reload

```bash
# vim /usr/lib/systemd/system/prometheus.service

[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
#User=prometheus  # 必须用该用户和相应的执行权限否则不能启动
#Group=prometheus
User=root
Group=root
Type=forking
Restart=on-failure
StandardError=/root/prom/logs/prometheus.log
StandardOutput=/root/prom/logs/prometheus.log

# ExecStart 后面不能带等号，所以要用换行符来写或者写成下面的启动脚本也行
ExecStart=/root/prom/prometheus \
--config.file /root/prom/prometheus.yml

[Install]
WantedBy=multi-user.target
```



### 启动脚本

```bash
#!/bin/bash
/root/prom/prometheus --config.file=/root/prom/prometheus.yml &>> /root/prom/logs/prometheus.log
```

