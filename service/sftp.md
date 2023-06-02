通过SFTP上传、删除文件，怎样记录日志呢，可以如此如此这般这般：
1.修改SSH配置：
   vim /etc/ssh/sshd_config
# 修改

   Subsystem       sftp    /usr/lib64/ssh/sftp-server -l INFO -f AUTH

2. 修改rsyslog
   vim /etc/rsyslog.conf
# 增加一行
   auth,authpriv.*                                         /var/log/sftp.log

3. 重启后查看/var/log/sftp.log
/etc/init.d/rsyslog restart
/etc/init.d/sshd restart
cat /var/log/sftp.log