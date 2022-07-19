<!--

 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2022-02-13 13:54:26
 * @LastEditors: clement-jiao
 * @LastEditTime: 2022-02-13 13:54:33
-->

# dhclient请求特定的IP地址

*假如我们要请求的地址是192.168.1.10，网卡为eth0*

（1）编辑`/etc/dhcp/dhclient.conf`，添加如下几行

```bash
interface "eth0" {
    send dhcp-requested-address 192.168.1.10;
}
```

这里指定了接口，只有 eth0 的接口获取 IP 时才会发送这个 request

（2）然后以root命令运行如下语句

```
1. dhclient -r -v eth0
2. dhclient -4 -d -v -cf /etc/dhcp/dhclient.conf eth0
```

参数解释：

- -r 释放地址
- -v 显示详细信息
- -4 只请求ipv4地址
- -d 运行在前台，貌似默认也运行在前台
- -cf 配置文件路径，上面修改的是默认配置，所以不加这个参数也行

## **其他**

从配置文件可知，如果要改hostname，那么修改`send host-name`那行即可

## **参考资料**

- man dhclient
- man dhclient.conf
