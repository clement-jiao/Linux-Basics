#### vlan (Linux 虚拟化网络)

```
nmcli con add con-name ens4-vlan10 ifname ens4-vlan10 type vlan id 10  dev ens4 ipv4.address 10.10.10.1/24 ipv4.method man
```

#### bound (链路聚合) team

网卡绑定的 7 种模式

```
active-backup (主备模式)
lacp (链路聚合模式)
```



