### windTerm 常见问题

debian11：没有可用文件管理器
```bash
# vim /etc/ssh/sshd_config
#Subsystem  sftp  /usr/lib/openssh/sftp-server
Subsystem sftp internal-sftp


# 如有需要对其权限进行限制
# Match Group sftp
#     ChrootDirectory %h
#     AllowTcpForwarding no
#     X11Forwarding no
#     ForceCommand internal-sftp
```