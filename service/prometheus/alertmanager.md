<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-30 16:59:48
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-11-30 17:10:00
-->

### prometheus 报警插件
##### 启动alertmanager
```bash [root@prom ~]$ alertmanager  --config.file alertmanager.yaml```
```bash default_port: http://[your ip add]:9093 ```

##### 主配置: 邮件告警参考
```yaml
global:
  smtp_smarthost: "smtp.126.com:25"
  smtp_from: "xxxx@126.com"
  smtp_auth_username: "xxxx@126.com"
  smtp_auth_password: "123456"
  smtp_require_tls: false   # 不使用tls加密

route:
  receiver: mail

receivers:
  - name: mail
  email_configs:
    - to: "1004402969@qq.com"
```
##### prometheus配置: 添加alertmanager
```yaml
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - 192.168.11.172:9093
```
