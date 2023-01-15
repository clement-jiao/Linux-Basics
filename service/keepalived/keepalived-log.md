## Keepalived 日志
#### 默认日志
默认日志存放在系统日志：/var/log/messages下
```bash
[root@lb01 /]# tail -f  /var/log/messages
Oct  6 13:30:07 lb01 Keepalived_vrrp[3671]: Kernel is reporting: interface eth0 UP
Oct  6 13:30:07 lb01 Keepalived_vrrp[3671]: VRRP_Instance(VI_1) Transition to MASTER STATE
Oct  6 13:30:08 lb01 Keepalived_vrrp[3671]: VRRP_Instance(VI_1) Entering MASTER STATE
Oct  6 13:30:08 lb01 Keepalived_vrrp[3671]: VRRP_Instance(VI_1) setting protocol VIPs.
Oct  6 13:30:08 lb01 Keepalived_vrrp[3671]: VRRP_Instance(VI_1) Sending gratuitous ARPs on eth0 for 192.168.119.150
Oct  6 13:30:08 lb01 Keepalived_healthcheckers[3670]: Netlink reflector reports IP 192.168.119.150 added
Oct  6 13:30:13 lb01 Keepalived_vrrp[3671]: VRRP_Instance(VI_1) Sending gratuitous ARPs on eth0 for 192.168.119.150
Oct  6 13:30:48 lb01 dhclient[856]: DHCPREQUEST on eth0 to 192.168.119.254 port 67 (xid=0x32903a31)
Oct  6 13:30:48 lb01 dhclient[856]: DHCPACK from 192.168.119.254 (xid=0x32903a31)
Oct  6 13:30:50 lb01 dhclient[856]: bound to 192.168.119.128 -- renewal in 783 seconds.
```

#### 把日志单独存放

修改/etc/sysconfig/keepalived

把KEEPALIVED_OPTIONS="-D" 修改为：KEEPALIVED_OPTIONS="-D -d -S 0"

```bash
[root@lb01 /]# vim /etc/sysconfig/keepalived 
# Options for keepalived. See `keepalived --help' output and keepalived(8) and
# keepalived.conf(5) man pages for a list of all options. Here are the most
# common ones :
#
# --vrrp               -P    Only run with VRRP subsystem.
# --check              -C    Only run with Health-checker subsystem.
# --dont-release-vrrp  -V    Dont remove VRRP VIPs & VROUTEs on daemon stop.
# --dont-release-ipvs  -I    Dont remove IPVS topology on daemon stop.
# --dump-conf          -d    Dump the configuration data.
# --log-detail         -D    Detailed log messages.
# --log-facility       -S    0-7 Set local syslog facility (default=LOG_DAEMON)
#

KEEPALIVED_OPTIONS="-D -d -S 0"
```

#### rsyslog
在/etc/rsyslog.conf 末尾添加
```bash
[root@lb01 /]# vim /etc/rsyslog.conf 
local0.*                                                /var/log/keepalived.log
```

#### 重启服务
```bash
# 注意服务重启顺序！
systemctl restart rsyslog.service
systemctl restart keepalived.service
```

#### 查看日志
```bash
[root@lb01 /]# tail -f /var/log/keepalived.log 
Oct  6 13:48:22 lb01 Keepalived_healthcheckers[3998]:  Using autogen SSL context
Oct  6 13:48:22 lb01 Keepalived_healthcheckers[3998]: Using LinkWatch kernel netlink reflector...
Oct  6 13:48:22 lb01 Keepalived_vrrp[3999]: VRRP sockpool: [ifindex(2), proto(112), unicast(0), fd(10,11)]
Oct  6 13:48:22 lb01 Keepalived_vrrp[3999]: VRRP_Instance(VI_1) Transition to MASTER STATE
Oct  6 13:48:22 lb01 Keepalived_vrrp[3999]: VRRP_Instance(VI_1) Received lower prio advert, forcing new election
Oct  6 13:48:23 lb01 Keepalived_vrrp[3999]: VRRP_Instance(VI_1) Entering MASTER STATE
Oct  6 13:48:23 lb01 Keepalived_vrrp[3999]: VRRP_Instance(VI_1) setting protocol VIPs.
Oct  6 13:48:23 lb01 Keepalived_healthcheckers[3998]: Netlink reflector reports IP 192.168.119.150 added
Oct  6 13:48:23 lb01 Keepalived_vrrp[3999]: VRRP_Instance(VI_1) Sending gratuitous ARPs on eth0 for 192.168.119.150
Oct  6 13:48:28 lb01 Keepalived_vrrp[3999]: VRRP_Instance(VI_1) Sending gratuitous ARPs on eth0 for 192.168.119.150
```