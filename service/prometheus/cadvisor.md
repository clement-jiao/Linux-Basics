<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-30 14:00:09
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-11-30 14:34:22
-->

### 容器宿主机监控 CAdvisor
##### 简介
1. 为了解决容器的监控问题，Google开发了一款容器监控工具 cAdvisor（Container Advisor），它为容器用户提供了对其运行容器的资源使用和性能特征的直观展示。 它是一个运行守护程序，用于收集，聚合，处理和导出有关正在运行的容器的信息。

2. cAdvisor可以对节点机器上的资源及容器进行实时监控和性能数据采集，包括CPU使用情况、内存使用情况、网络吞吐量及文件系统使用情况。

3. cAdvisor使用go语言开发，如果想了解更多请访问其官方 github：https://github.com/google/cadvisor

##### 安装CAdvisor
cAdvisor 有两种方法来运行，一种是以二进制可执行文件安装运行，另一种是以 Docker 容器运行。这里我们主要介绍第二种以Docker方式安装运行。
```bash
docker run \
  --volume=/:/rootfs:ro \    # 挂载只读磁盘
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \      # 开放8080端口
  --detach=true \            # 保持后台运行
  --name=cadvisor \          # 指定容器名称
  google/cadvisor:latest     # 指定镜像版本
```
以docker方式运行成功后，可以通过 http://[Your Host IP]:8080（默认是8080端口）来访问cAdvisor。
