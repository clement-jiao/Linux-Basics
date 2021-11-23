### ansible注意事项

Ansible.cfg 默认配置

```bash
[defaults]
inventory = ./inventory
remote_user = someuser
ask_pass = false

[privilege-escalation]
becom = true						# 是否提权
becom_method = sudo
becom_user = root
becom_ask_pass = false
```

