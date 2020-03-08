<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-02-15 21:06:22
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-02-15 21:06:22
 -->
### ansible 常用配置与参数
#### inventory 常用参数说明
```yaml
inventory: 定义托管主机地址的配置文件路径
[webserver:vars]
ansible_ssh_host: 将要连接的远程主机名与你想要设定的主机别名不同，可以通过此变量设置
ansible_ssh_port: ssh端口号，如果不是默认的端口号，通过此变量设置
ansible_ssh_user: ssh登录用户名
ansible_ssh_pass: ssh密码（这种方式并不安全，强烈建议使用 --ask-pass 或 SSH 密钥）
ansible_sudo_pass: sudo密码（建议使用 --ask-sudo-pass）
ansible_sudo_exe: sudo命令路径（适用于1.8及以上版本）
ansible_connection: 与主机的连接类型，如：local，ssh或paramiko，1.2以前默认使用paramiko，1.2以后默认使用‘smart’，它会根据是否支持ControlPersist来判断‘ssh’方式是否可行
ansible_ssh_private_key_file: ssh使用的私钥文件，适用于有多个密钥，而你不想使用SSH代理的情况
ansible_shell_type: 目标系统的shell类型，默认情况下，命令的执行使用‘sh’语法，可设置为‘sch’或‘fish’
ansible_python_interpreter: 目标主机的python路径，适用情况：系统中有多个Python，或者命令路径不是“/usr/bin/python”
```
