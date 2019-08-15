<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-15 00:07:05
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-15 18:59:19
 -->
#Tomcat环境安装及与apache整合
##安装Java与apache
- 安装
  ```bash
  yum install -y java-1.8.0-openjdk-devel.x86_64 \
  java-1.8.0-openjdk.x86_64 \
  httpd httpd-devel
  ```

- 配置Java环境变量

  ```bash
  export JAVA_HOME=/usr/lib/jvm/java-latest
  export JRE_HOME=$JAVA_HOME/jre
  export JAVA_BIN=$JAVA_HOME/bin
  export JAVA_LIB=$JAVA_HOME/lib
  export CLASSPATH=.:$JAVA_LIB/tools.jar:$JAVA_LIB/dt.jar
  export PATH=$JAVA_BIN:$PATH
  ```

- 安装完毕后，运行java -version 将输出如下内容：

  ```
  [root@localhost temp]# java -version
  openjdk version "1.8.0_222"
  OpenJDK Runtime Environment (build 1.8.0_222-b10)
  OpenJDK 64-Bit Server VM (build 25.222-b10, mixed mode)】

  [root@localhost temp]# httpd -v
  Server version: Apache/2.4.6 (CentOS)
  Server built:   Jul 29 2019 17:18:49
  ```
***
##下载Tomcat 及连接器
tomcat 版本：8.5.43，可以去官网下载最新版本的 [tomcat 8.5.x](https://tomcat.apache.org/download-80.cgi) 。

```bash
wge http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v8.5.43/bin/apache-tomcat-8.5.43.tar.gz
```

jk_mod 版本：1.2.46 可以去官网下载最新版本的 [Tomcat Connectors JK 1.2](http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz)

```bash
wget http://mirror.bit.edu.cn/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz

yum install -y gcc gcc* gcc-c++ ntp make imake cmake automake autoconf    # 确认是否安装 gcc

tar zxf tomcat-connectors-1.2.46-src.tar.gz
mv tomcat-connectors-1.2.46-src jk
cd jk/apache2.0 & ./configure --with-apxs=/usr/bin/apxs    # 先确认apxs是否在那个目录中，如果没有就安装 httpd-devel
make
cp jk/conf/* /etc/httpd/conf.d
```
***
##添加Tomcat用户

```bash
useradd -m -U -d /home/tomcat -s /bin/false tomcat
```
***
##安装 tomcat 连接器

首先确认 httpd httpd-devel 与 tomcat 都已经安装完成，然后进行mod_jk的安装
```bash
tar -zxf tomcat-connectors-1.2.42-src.tar.gz -C jk
cd jk/native/
./configure --with-apxs=/usr/bin/apxs         # 如果找不到这个命令则需要安装 httpd-devel
make                                          # 记得安装gcc
cp ./apache-2.0/mod_jk.so /etc/httpd/modules/ # 把编译好的mod_jk.so拷贝到自己httpd的modules目录下
```
***
##修改Tomcat目录权限

  - 将目录所有权更改为tomcat：tomcat：

    ```bash
    chown -R tomcat:tomcat /tomcat
    ```

  - 为bin目录添加可执行权限

    ```bash
    chmod +x /tomcat/latest/bin/*.sh
    ```

  >Tomcat 8.5经常更新，可以创建软连接tomcat-latest指向Tomcat目录
***
##创建systemd unit 文件
可以更方便的管理Tomcat进程

```bash
# vim /etc/systemd/system/tomcat.service

[Unit]
Description=Tomcat 8.5 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-latest"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"

Environment="CATALINA_BASE=/tomcat/latest"
Environment="CATALINA_HOME=/tomcat/latest"
Environment="CATALINA_PID=/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/tomcat/latest/bin/startup.sh         # 注意更改路径，一般出错都是路径配置不对
ExecStop=/tomcat/latest/bin/shutdown.sh         # 注意更改路径，一般出错都是路径配置不对

[Install]
WantedBy=multi-user.target
```
***
##重启 systemd 服务
重启 systemd 并通过执行以下命令启动Tomcat、apache服务：

```bash
systemctl daemon-reload
systemctl restart tomcat httpd
```
***
##检查服务状态

```bash
systemctl status tomcat               # 检查服务状态是因为即使启动失败也不会报错

systemctl enable tomcat               # 如果没出错可以设置成开机启动

systemctl enable --now tomcat httpd   # 也可以这样写：设置开机自启并启动服务
```

- 如果启动失败
  1. **tomcat.service 路径不对**
  2. **tomcat 目录权限没改**
  3. **tomcat bin目录没加执行权限**
***
##关闭防火墙
- 彻底关闭

  ```bash
  systemctl stop firewalld.service
  ```

- 放行
  ```bash
  firewall-cmd --zone=public --permanent --add-port=8080/tcp
  firewall-cmd --reload
  ```
***
##配置 Tomcat 管理界面
要添加一个能够访问tomcat web界面的新用户（manager-gui和admin-gui），需要在 tomcat-users.xml 文件中定义用户，如下所示：

- 修改 tomcat-users.xml 文件
  ```xml
  <!-- vim /tomcat/conf/tomcat-users.xml -->

  <!-- 取消37行注释并修改<tomcat-users>...</tomcat-users>区域 -->

    <role rolename="tomcat"/>
    <role rolename="manager-gui"/>
    <role rolename="admin-gui"/>
    <role rolename="manager-script"/>
    <role rolename="admin-script"/>
    <user username="tomcat" password="tomcat" roles="tomcat,manager-gui"/>

    <!--
      注意最后一行role设置且在403页面上有说明：
      请注意，对于Tomcat 7以上，使用管理器应用程序所需的角色已从单个管理器角色更改为以下四个角色。您需要分配您希望访问的功能所需的角色。
      manager-gui：允许访问HTML GUI和状态页面
      manager-script：允许访问文本界面和状态页面
      manager-jmx：允许访问JMX代理和状态页面
      manager-status：仅允许访问状态页面

      HTML接口受CSRF保护，但文本和JMX接口不受保护。为了保持CSRF保护：
        具有 manager-gui 角色的用户 不应 被授予 manager-script 或 manager-jmx 角色。
        如果通过浏览器访问text或jmx接口（例如，为了测试，因为这些接口用于工具而非人类），则必须在之后关闭浏览器以终止会话。
    -->
  ```

- 修改 manager.xml 文件
  ```xml
  <!-- vim /tomcat/conf/Catalina/localhost/manager.xml -->
  <Context privileged="true" antiResourceLocking="false"
        docBase="${catalina.home}/webapps/manager">
    <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />
  </Context>
  ```
  >保存退出并重启: systemctl restart tomcat

***
##修改mod_JK配置以连接apache
JK最关键的四个文件分别是：
```text
httpd.conf：Apache 服务器的配置文件，用来加载JK模块以及指定JK配置文件信息

httpd-jk.conf： 是 module/mod_jk.so 模块的配置文件,用来通知 apache 将哪些文件转发至 tomcat 来处理

worker.properties： tomcat 服务器的连接文件

uriworkermap.properties：URL映射文件，用来指定哪些URL由tomcat处理，也可以指定哪些URL不让tomcat处理，取反用!号。
```
  - **httpd.conf**
    ```bash
    # vim /etc/httpd/conf/httpd.conf

    修改 ServerName ： {{ 本机地址 }}
    ```
  - **worker.properties**
    [Apache+JK+Tomcat负载平衡配置](http://binnyblog.com/article/199)一文说明了jk_mod分发请求类型
    ```bash
    # vim /etc/httpd/conf.d/tomcat/worker.properties

    worker.list=connect,jk-status,tomcat1   # tomcat 名称，后面的httpd-jk.conf、uriworkermap.properties、server.xml需要一致或存在此列表
    worker.tomcat1.type=ajp13               # 使用的协议：AJP/13
    worker.tomcat1.host=192.168.0.50        # tomcat地址
    worker.tomcat1.port=8009                # tomcat端口
    worker.tomcat1.lbfactor=1               # 服务器权重

    #=========controller==========          # 负载均衡器
    # worker.controller.type=lb               # 采用类型为 lb 负载均衡类型
    # worker.connect.balanced_workers=tomcat1 # 指定负载列表，逗号分隔
    # worker.connect.sticky_session=false     # 此处指定集群是否需要会话复制，如果设为true，则表明会话粘性，不进行会话复制，当某用户的请求第一次分发到哪一 tomcat 后，
                                            # 后续的请求会一直分发到此台 tomcat 服务器上处理；如果设为 false ，则表明需要会话复制。
    worker.connect.sticky_session_force=1   # 这样负载均衡器lb 就会尽量保持一个session，也就是使用户在一次会话中跟同一个 tomcat 进行交互

    #===========status============
    worker.status.type=status               # 用于 httpd 自身状态监控的 status
    ```

  - httpd-jk.conf
    ```bash
    # vim /etc/httpd/conf.d/httpd-jk.conf
    LoadModule jk_module modules/mod_jk.so  # 全局只需加载/写一次
    <IfModule jk_module>

      JkWorkersFile conf.d/tomcat/workers.properties  # 指明 worker 的配置文件
      JkLogFile logs/mod_jk.log             # 日志路径
      JkLogLevel info                       # 日志记录级别
      JkShmFile logs/mod_jk.shm             # 共享内存文件
      JkMount /tomcat/webapps/power/*.jsp tomcat1      # 哪些目录下的文件需要被哪个tomcat转发

    <IfModule jk_module>
    ```

  - uriworkermap.properties
    追加如下行：
    ```bash
    # vim /etc/httpd/conf.d/tomcat/uriworkermap.properties
    !/*=connect
    !/*.gif=tomcat1         # 将以 .gif 结尾的文件 不转发 至 tomcat 处理
    !/*.jpg=tomcat1         # 去掉 ！ 号，将由 tomcat 来处理
    !/*.png=tomcat1
    !/*.css=tomcat1
    !/*.js=tomcat1
    !/*.htm=tomcat1
    !/*.html=tomcat1
    ```
  - server.xml
    在tomcat中配置 jvmRoute，与 workers.properties 中指名的 worker 对应

    ```xml
    <!-- vim /tomcat/conf/server.xml -->

    <Engine name="Catalina" defaultHost="localhost" jvmRoute="tomcat1">

    ```
    > systemctl restart httpd tomcat

***

##相关文档或资料
  - [关于 Include conf/mod_jk.confd 的说明](http://binnyblog.com/article/199)
  - [workers.properties 官方文档](http://tomcat.apache.org/connectors-doc/reference/workers.html)
  - [workers.properties 相关博客](https://blog.csdn.net/yuanyuan_186/article/details/51290912)
  - [关于访问资源500的说明](https://support.plesk.com/hc/en-us/articles/115003727873-Website-on-Tomcat-shows-500-error-Could-not-find-worker-with-name)
