<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-04-04 23:05:36
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-04-05 02:54:33
 -->


### docker常用操作命令

#### docker的特性与虚拟机的异同:
1. 安装虚拟机软件如: VMware, 在此虚拟机软件上安装操作系统(下载), 把操作系统的虚拟机文件备份, 随时复制并启动该操作系统.
2. 在Linux上安装docker软件, 从镜像仓库拉取(pull)操作系统或应用环境,基于该镜像文件创建一个容器(运行环境),备份容器以供下次使用(直接export容器, 将容器提交(commit)为本地镜像).
3. 虚拟机环境直接完全模拟一套全新的硬件环境,docker环境不虚拟硬件,直接使用宿主机资源(docker默认下不限制cpu,内存资源),也可以直接指定分配某个容器的cpu或内存资源.
4. 虚拟机可以直接与宿主机或局域网连接,分配IP地址(brige,nat), docker容器无法获取IP地址(跟随于宿主机的IP地址).
5. 镜像相当于是容器的模板,通过镜像创建容器,容器修改后也可以提交为镜像,删除容器并不会删除镜像,删除镜像则无法创建容器.

#### 容器使用注意事项:
1. 尽量让一个容器做一件事情,或启动一个服务.
2. 尽量使用挂载的方式将数据文件挂在到容器中,容器里面尽量不要保存数据.
3. 尽量让容器按照docker化的要求来使用容器, 而不是安装一个虚拟机.
4. 尽量不适用交互模式来直接操作容器, 而是在宿主机上执行命令, 或者使用docker file

#### 安装docker
1. 安装网络相关命令: yum install net-tools
2. 安装实用工具: yum install -y yum-utils device-mapper-persistent-data lvm2
3. 添加yum镜像: yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
4. 更新yum缓存: yum makecache fast
5. 安装docker-ce: yum -y install docker-ce
6. 启动docker服务: systemctl --now start docker.service
7. 查看docker信息: docker info
8. 查找centos可用镜像: docker search centos
9. 镜像仓库地址: https://hub.docker.com     https://hub.daocloud.io
10. 查看docker服务器, systemctl list-unitsfiles | grep docker, 如果显示disabled, 说明docker服务不会开机自启.需要 systemctl enable docker
>注意事项:建议在centos7版本上安装docker,确保有足够的硬盘空间,确保内存和cpu资源足够.

#### 快速验证安装是否成功:
1. 搜索镜像: docker search mysql
2. 拉取镜像: docker pull mysql  默认情况下, 会拉取最新版本镜像(:latest),如需制定版本, 则必须指定tag标签.
3. 运行镜像: docker run mysql
4. 查看镜像: docker images
5. 查看容器: docker ps, docker container ls -a
6. 启动容器: docker start/stop/restart mysql
7. 删除容器: docker rm 容器名
8. 删除镜像: docker rmi mysql

#### 安装 mysql 5.6:
1. 在docker hub上拉取镜像: docker pull mysql:5.6.46
2. 在 daocloud 上拉取镜像: docker pull daocloud.io/library/mysql:5.6.22
3. 创建一个容器, 指定容器名称和主机名称: docker create --name mysql-5.6 -h mysql5.6 daocloud.io/library/mysql:5.6.22
4. 列出所用容器: docker container ls -a     docker ps -a
5. 查看目前正在运行的容器: docker ps
6. 启动容器: docker start mysql-5.6
7. 重新创建并启动: docker run --name mysql-5.6 -e MYSQL_ROOT_PASSWORD=123456 -d daocloud.io/library/mysql:5.6.22
8. 删除一个容器: docker rm mysql-5.6
9. 添加映射端口: docker run --name mysql-5.6 -p 53306:3306
10. 停止容器: docker stop mysql-5.6

#### 安装 Tomcat8.0:
1. 拉取镜像: docker pull daocloud.io/library/Tomcat:8.0.23-jre8
2. 解压war包到/workspace目录用于挂在到tomcat容器中: unzip -oq erp.war -d ./workspace
3. 创建并启动: docker run --name tomcat-8.0 -h tomcat8.0 -p 8081:8080 -d -v /workspace:/usr/local/tomcat/webapps/workspace daocloud.io/library/tomcat:8.0.23-jre8
4. 修改 db.properties, 确保连接到正确的mysql数据库上. (可以docker exec -it tomcat-8.0)
5. 重启容器: docker restart tomcat-8.0

#### 直接安装裸 centos 并自己配置环境
1. 拉取centos7.6镜像: docker pull daocloud.io/library/centos:7.6.1810
2. 创建并启动镜像, 考虑到需要启动mysql, 所以需要使用特权模式: --privileged=true centos:7.6.1810 /sbin/init

#### 特殊场景
1. 特权模式: docker run -itd --name centos-all -p 8081:8080 -p 23:22 -p 3307:3306 --privileged=true centos:7.6.1810 /sbin/init
2. 限制cpu和内存: https://www.cnblogs.com/zhuochong/p/9728383.html
3. 环境变量: -e JAVA_HOME=/optjdk
4. 自动启动: /etc/rc.d/rc.local   开机自动运行脚本: chmod +x /etc/rc.d/rc.local
5. 配置基于ubuntu的vnc server,可通过vnc viewer或web页面直接操作ubuntu的界面,适用于构建一些临时的实验环境: docker run --name ubuntu-vnc -d -p 6080:80 -p 5900:5900 -e VNC_PASSWORD=123456 -e RESOLUTION=1440x900 -v /dev/shm:/dev/shm dorowu/ubuntu-desktop-lxde-vnc
6. 如何将宿主机的目录与容器内的目录进行交换? 可视化你的容器内容!
  使用场景:
    - 统一管理安装包, 不让所有安装包散落在各个容器的各个目录;
    - 让容器的数据存储使用一块新买的磁盘;
    - 复制同一份代码到新容器中使用,从而方便后续独立的修改;
    - 无法进入到容器,却想拿到其中的数据;
    - >所以需要使用到目录映射功能,这是docker 自带的功能,方便实用: -v 参数设置即可.
7. 查看容器的资源使用率: docker stats --no-stream
8. 查看容器的IP地址: docker inspect mysql-5.6 | grep ipaddress
9. 复制文件到容器中: docker cp /host/file containerName:/etc/timezone
10. 容器或镜像的导出/导入: docker export/import container, docker save/load image
11.将容器提交为镜像: docker commit containerName













































