## OSI 模型 与 TCP/IP模型

### 1.OSI七层框架

ISO：<font color=red>*国际标准化组织*</font>
OSI：<font color=red>*开放系统互联*</font>
IOS：<font color=red>*思科交换机和路由器的操作系统*</font>

- OSI七层模型
1. 各层的主要作用：
  - 第7层（应用层）：各种应用
  - 第6层（表示层）：将汉字、英文、图片、声音和影像翻译为二进制
  - 第5层（会话层）：判断当前数据是否要进行远程会话
  - 第4层（传输层）：判断数据发送的协议（TCP/UDP），判断端口
  - 第3层（网络层）：确定IP地址（源IP、目标IP）
  - 第2层（数据链路层）：确定MAC地址
  - 第1层（物理层）：通过网线和网卡等物理设备在主机之间进行数据的传输

### 2.各层的主要作用
| OSI层             | 用途          | 作用           | TCP/IP协议    |
|:-------------:|:------------- |:------------- |:------------- |
|应用层<br>(application layer)|文件传输、电子邮件、文件服务|用户接口|TFTP,HTTP,SNMP,<br>FTP,SMTP,DNS,TELENT|
|表示层<br>(persentation)|数据格式化，代码转换，数据加密 |数据的表示、安全、压缩|没有协议|
|会话层<br>(session layer)|解除或建立与别的接点的联系|建立、管理、中止会话|没有协议|
|传输层<br>(transport layer)|提供端对端的接口|可靠与不可靠的传输，传输的错误检测，流控|TCP，UDP|
|网络层<br>(network layer)|为数据包选择路由|进行逻辑地址寻址，实现不同网络之间的路由选择|IP，ICMP，RIP，<br>OSPF，BGP，IGMP|
|数据链路层<br>(data link layer)|传输有地址的帧以及错误检测功能 |组帧，进行硬件地址寻址，差错检验等功能|SLIP，CSLIP，PPP，<br>ARP，RARP，MTU
|物理层<br>(physical layer|以二进制数据形式在物理媒体上传输数据|设备之间的比特流传输，物理接口，电气特性等|ISO2110，IEEE802，IEEE802.2|

| OSI七层网络模型 | Linux的TCP/IP概念层| 对应网络协议 | 相应措施       |
|:-------------:|:------------- |:------------- |:------------- |
|应用层<br>(application layer)||TFTP,FTP,NFS,WAIS||
|表示层<br>(persentation)|应用层|telent,rlogin,snmp,gopher|Linux应用命令测试|
|会话层<br>(session layer)||smtp,dns||
|传输层<br>(transport layer)|传输层|TCP,UDP||
|网络层<br>(network layer)|网际层|IP,ICMP,ARP,RARP,AKP,UUCP||
|数据链路层<br>(data link layer)|网络接口|FDDI,ethernet,arpanet,PDN,SLP,PPP|ARP地址检测、物理连接检测|
|物理层<br>(physical layer||IEEE 802.1A到IEEE 802.11|
### 3.TCP/IP模型
![TCP模型]( img/OSI七层模型.gif "TCP模型")
现在一般被公认的就是TCP/IP 5，因为<font color=red>数据链路层</font>中的协议是真实的物理硬件交换机来完成的，不能将它归为<font color=red>网络接口层</font>中。


### 4.TCP/IP协议族的组成
![TCP协议族]( img/TCPIP协议族.jpg "TCP协议族")

- <font color=blue>**应用层**</font>
  **HTTP**：超文本传输协议
  **FTP**： 文件传输协议
  **TFTP**：简单文件传输协议，现在多用于思科路由器和交换机升级操作系统。
  **SMTP**：简单邮件传输协议
  **POP3**：邮局协议3代
  **SNMP**：简单网络管理协议$\Rightarrow$集群监控服务器
  **DNS**： 域名系统
- <font color=EEE9>**传输层**</font>
  **TCP**：传输控制协议
  **UDP**：用户数据报协议
- <font color=green>**网络层**</font>
  **IP**：网际协议
  **ARP**：(**Address Resolution Protocol**)，地址解析协议。将一个已知的IP地址解析成MAC地址。
  **RARP**：反向地址解析协议
  **ICMP**：互联网控制消息协议
  **IGMP**：网络组管理协议
- <font color=green>**物理层**</font>
  **PPP**：点对点协议
  **PPPOE**：点对点拨号协议

### 5.数据包封装过程
![数据包封装过程]( img/数据包封装过程.gif "数据包封装过程")
|层|封装|解封装|
| :---: | :---- | :---- |
|应用层|$\Downarrow$上层数据|$\Uparrow$上层数据|
|传输层|$\Downarrow$上层数据<font color=red>**+TCP头部**</font>|$\Uparrow$上层数据<font color=red>**-TCP头部**</font>|
|网络层|$\Downarrow$上层数据+TCP头部<font color=red>**+IP头部**</font>|$\Uparrow$上层数据+TCP头部<font color=red>**-IP头部**</font>|
|数据链路层|$\Downarrow$上层数据+TCP头部+IP头部<font color=red>**+MAC头部**</font>|$\Uparrow$上层数据+TCP头部+IP头部<font color=red>**-MAC头部**</font>|
|物理层|$\Downarrow$比特流|$\Uparrow$比特流|


### 6.设备与层之间对应的关系


|互联设备|工作层次|主要功能|
| :----: | :---: | :---: |
|计算机|应用层||
|中继器|
|网桥|传输层|防火墙|
|路由|网络层|路由器|
|网关|数据链路层|交换机|
|物理层|网卡|
位于高层的设备可以认识底层的东西，但是底层的设备不能识别高层的协议。
MAC地址是固化在网卡的ROM中。


### 7.各层之间通信
![各层之间通信](328bd8cc-0693-44da-8a9e-a27d932f634d*128*files/*u5404*u5C42*u4E4B*u95F4*u901A*u4FE1.PNG "各层之间通信")


>计算机A向计算机B发送数据。</br>从应用层到传输层，在传输层中数据包封入源端口和目标端口，比如网页服务，源端口是随机的，目标端口是80；</br>从传输层到网络层，在网络层中写入源IP和目标IP，源IP是A主机的IP地址，目标IP是B主机的IP地址；</br>从网络层到数据链路层，在数据链路层中写入源MAC地址和目标MAC地址，源MAC是A主机的MAC地址，目标MAC是交换机的MAC地址；</br>数据包通过物理层发送;</br>数据包被交换机的1/0口接收，交换机获取包头中的目标MAC地址，通过泛洪向局域网内所有网卡的MAC地址发起询问。</br>路由器回应后，交换机通过网线将数据包发送至路由器。</br>路由获取数据包后读取包头中目标MAC地址，确定是本机的MAC地址后，将数据包向上一层传递。</br>网络层获取数据包中的目标IP地址，通过广播向网络中所有的路由器询问目标IP地址。</br>B路由器回复信息，A路由器将B路由器的MAC地址更改为数据包包头中的目标MAC地址。</br>数据包传递给B路由器，路由器确定过MAC地址后，将数据包向上层传递。</br>路由器确定目标IP后，确认这个数据包是传给自己的，传给交换机B。</br>交换机读取包头中的MAC地址，对照内存中的MAC对照表，通过RARP协议将IP翻译为MAC地址，传送给目标IP的主机。
