<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-06-13 20:48:01
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-06-13 21:14:17
-->
### docker 部署 pgsql时, data目录不生效问题

今天用docker部署postgresql，用的是官方的镜像。结果挂载完 /var/lib/postgresql/data目录后，和容器里的目录其实并没有挂载成功。
宿主机上的目录并没有成功挂载到容器里，原因是官方镜像默认挂载了这个目录（/var/lib/postgresql/data）。
所以解决办法就是，把自己的宿主机的data目录映射到容器里的其他目录，然后通过设置环境变量 PGDATA 为容器里的新目录，即可。
