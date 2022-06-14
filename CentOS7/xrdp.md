## CentOS7 安装桌面环境

### 安装桌面软件包

```bash
# 查看软件包

[root@localhost ~]$ yum grouplist|grep "GNOME Desktop"
>   GNOME Desktop

yum -y groupinstall "GNOME Desktop" "Graphical Administration Tools"
```

#### 运行级别

```bash
# 切换运行级别
init 5

# 查看确认当前运行级别
runlevel
> 3 5
# 3 上次运行级别，5 本次运行级别
```

#### 查看是否有运行中的桌面进程。

```bash
[root@localhost ~]$ ps -A | egrep -i "gnome|kde|mate|cinnamon|lx|xfce|jwm"
#    38 ?        00:00:00 kdevtmpfs
# 10590 ?        00:00:00 gnome-terminal-
# 10596 ?        00:00:00 gnome-pty-helpe
# 20492 ?        00:00:00 gnome-session-b
# 20530 ?        00:00:16 gnome-shell
# 20740 ?        00:00:11 gnome-initial-s
# 20794 ?        00:00:00 gnome-keyring-d
# 21238 ?        00:00:00 gnome-session-b
# 21438 ?        00:00:00 gnome-keyring-d
# 21448 ?        01:46:49 gnome-shell
# 21504 ?        00:00:00 gnome-shell-cal
# 21691 ?        00:00:08 gnome-software
```

以上gnome启动成功

### 安装xrdp和vnc服务

#### 配置 epel

#### 安装 vnc和xrdp

```bash
yum -y install xrdp tigervnc-server
```

#### 启动服务

```bash
systemctl enable --now xrdp.service
```

### 连接

打开远程桌面工具 - 填入地址连接

### kernel-devel

centos.pkgs.org
download 链接多试几次就能下载成功了

















