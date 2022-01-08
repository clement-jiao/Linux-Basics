<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-19 13:17:53
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-20 15:42:18
 -->
  #在CentOS 7上安装 HAProxy 1.8

## 简介
HAProxy 提供高可用性、负载均衡以及基于TCP和HTTP应用的代理，支持虚拟主机，它是免费、快速并且可靠的一种解决方案。HAProxy 特别适用于那些负载特别大的 web 站点，这些站点通常又需要会话保持和七层处理。HAProxy运行在当前的硬件上，完全可以支持数以万计的并发连接。并且它的运行模式使得它可以很简单安全的整合进您当前的架构中，同时可以保护你的web服务器不被暴露在公网当中。

HAProxy 实现了一种事件驱动，单一进程模型，此模型支持非常大的并发连接数，多进程或多线程模型受内存限制、系统调度器限制以及无处不在的锁限制，很少能处理数千并发连接。事件驱动模型因为在有更好的时间和资源管理的用户端（user-space）实现所有这些任务，所以没有这些问题。此模型的弊端是，在多核系统上，此程序的扩展性通常比较差。这就是为什么他们必须进行优化以使得每个CPU时间片（Cycle）做更多的工作。

## HAProxy 版本


## 安装
如果安装了默认的HAProxy 1.5版，则应将其删除，因为它与新版本会产生冲突
  - 备份旧的配置文件
    ```bash
    yum remove haproxy
    
    # 注意：需要把 /etc/haproxy/haproxy.cfg 保存为 /etc/haproxy/haproxy.cfg.rpmsave
    # 重命名旧的 haproxy 配置文件，有助于你是否计划在HAProxy 1.8版中使用相同的文件。
    ```

  - 安装 centOS 软件集（SCL）存储库以访问新的 HAProxy 版本
    ```bash
    # 注意：如果未安装 centOS 源则安装版本可能为 1.5X
    
    yum install centos-release-scl-rh
    ```

    >更新存储库： yum makecache

  - 安装HAProxy 1.8
    ```bash
    yum install rh-haproxy18-haproxy rh-haproxy18-haproxy-syspaths
    ```

    >rh-haproxy18-haproxy-syspaths软件包是rh-haproxy18-haproxy软件包的系统级包装器，允许我们将HAProxy 1.8作为服务运行。此程序包与HAProxy冲突，无法在一个系统上安装。

  - 查看 /etc/haproxy/haproxy.cfg，将看到的新包的简单配置
    ```bash
    ls -l /etc/haproxy/
    # lrwxrwxrwx. 1 root root 44 Jul 17 18:19 haproxy.cfg -> /etc/opt/rh/rh-haproxy18/haproxy/haproxy.cfg
    ```

  - 设置haproxy开机自启并启动服务
    ```bash
    systemctl enable --now rh-haproxy18-haproxy
    
    systemctl status rh-haproxy18-haproxy         # 记得查看启动状态
    ```

## 配置

### 配置文件格式

  - HAProxy 配置处理3类主要参数来源
    1. 最优先处理的命令行参数
    2. 配置文件中 "global" 配置段，用于设定全局配置参数
    3. 配置文件中 "proxy" 相关配置段，如“defaults”，“listen”，“frontend”和“backend”

  - 配置文件中分成五部分内容，分别如下
    1. global：参数是进程级的，通常是和操作系统相关。这些参数一般只设置一次，如果配置无误，就不需要再次进行修改；
    2. defaults：配置默认参数，这些参数可以被用到frontend，backend，Listen组件；
    3. frontend：接收请求的前端虚拟节点，Frontend可以更加规则直接指定具体使用后端的backend；
    4. backend：后端服务集群的配置，是真实服务器，一个Backend对应一个或者多个实体服务器；
    5. Listen Fronted和backend的组合体。
  - 配置文件基础语法
    haproxy配置文件引入了引号和转义符：反斜线表示转义符；单引号表示强引用；双引号表示弱引用。如果字符串内需要输入空格，则空格需要进行转义或者通过引号包围，不转义时在配置文件中表示分隔符
    ```bash
    1. \    # 标记一个空白字符以区分它的本义和用作分隔符时的空白符
    2. \#   # to mark a hash and differentiate it from a comment
    3. \\   # 使用反斜杠
    4. \'   # 使用单引号并将其与强引用区分开来
    5. \"   # 使用双引号并将其与弱引用区分开来
    ```
    在配置文件中，一些包含了数值的参数表示时间，如timeout。这些值默认以毫秒为单位，但也可以使用其它的时间单位后缀。
    ```bash
    1. us: 微秒(microseconds)，即1/1000000秒；
    2. ms: 毫秒(milliseconds)，即1/1000秒；
    3. s: 秒(seconds)；
    4. m: 分钟(minutes)；
    5. h：小时(hours)；
    6. d: 天(days)；
    ```
  - 配置文件内容
    抛去不建议设置的项后，内容大致如下：这也是yum安装haproxy时默认提供的配置
    ```bash
    global
        daemon
        log         127.0.0.1 local2
        chroot      /var/lib/haproxy
        pidfile     /var/run/haproxy.pid
        maxconn     4000
        user        haproxy
        group       haproxy
        stats socket /var/lib/haproxy/stats
    fronrend http-in
      bind *:80
      default-backend servers
    
    backend servers
      server server1 127.0.0.1:8080 maxconn 32
    # 注意上面配置了使用local2记录log，因此还需去rsyslogd的配置文件中添加该设备以及记录的日志位置。如下
    #  cat <<eof>>/etc/rsyslog.conf
    #    local2.*     /var/log/haproxy.log
    #  eof
    ```

    完整配置与选项：更多参见[官方文档](https://cbonte.github.io/haproxy-dconv/1.8/intro.html)

    ```conf
    global  # 全局参数的设置
    
        log 127.0.0.1 local0 info
        # log语法：log <address_1>[max_level_1] # 全局的日志配置，使用log关键字，指定使用127.0.0.1上的syslog服务中的local0日志设备，记录日志等级为info的日志
    
        user haproxy
        group haproxy
        # 设置运行haproxy的用户和组，也可使用uid，gid关键字替代之
    
        daemon
        # 以守护进程的方式运行于后台，等同于命令行的"-D"选项，当然，也可以在命令行中以"-db"选项将其禁用；(建议设置项)
    
        nbproc 16
        # 设置haproxy启动时的进程数，根据官方文档的解释，我将其理解为：该值的设置应该和服务器的CPU核心数一致，即常见的2颗8核心CPU的服务器，即共有16核心，则可以将其值设置为：<=16 ，创建多个进程数，可以减少每个进程的任务队列，但是过多的进程数也可能会导致进程的崩溃。这里我设置为16
        # 默认只启动一个进程，一般只在单进程仅能打开少数文件描述符的场景中才使用多进程模式；(官方强烈建议不要设置该选项)
    
        maxconn 4096
        # 定义每个haproxy进程的最大连接数 ，由于每个连接包括一个客户端和一个服务器端，所以单个进程的TCP会话最大数目将是该值的两倍。
    
        #ulimit -n 65536
        # 设置最大打开的文件描述符数，在1.4的官方文档中提示，该值会自动计算，所以不建议进行设置，在1.8中已经废弃
    
        pidfile /var/run/haproxy.pid
        # 定义haproxy的pid
    
        stats socket /var/opt/rh/rh-haproxy18/lib/haproxy/stats
        # 和多进程haproxy有关，由于不建议使用多进程，所以也不建议设置此项。但建议设置为"stats socket"将套接字和本地文件进行绑定，如"stats socket /var/opt/rh/rh-haproxy18/lib/haproxy/stats"
    
        # 其他 global 选项
        # chroot ：修改haproxy工作目录至指定目录，可提升haproxy安全级别，但要确保必须为空且任何用户均不能有写权限；
        # uid/user：以指定的UID或用户名身份运行haproxy进程；
    
    defaults  # 默认部分的定义
        mode http
        # mode语法：mode {http|tcp|health} 。http是七层模式，tcp是四层模式，health是健康检测，返回OK
    
        log 127.0.0.1 local3 err
        # 使用127.0.0.1上的syslog服务的local3设备记录错误信息
    
        retries 3
        # 定义连接后端服务器的失败重连次数，连接失败次数超过此值后将会将对应后端服务器标记为不可用
    
        option httplog
        # 启用日志记录HTTP请求，默认haproxy日志记录是不记录HTTP请求的，只记录“时间[Jan 5 13:23:46] 日志服务器[127.0.0.1] 实例名已经pid[haproxy[25218]] 信息[Proxy http_80_in stopped.]”，日志格式很简单。
    
        option redispatch
        # 当使用了cookie时，haproxy将会将其请求的后端服务器的serverID插入到cookie中，以保证会话的SESSION持久性；而此时，如果后端的服务器宕掉了，但是客户端的cookie是不会刷新的，如果设置此参数，将会将客户的请求强制定向到另外一个后端server上，以保证服务的正常。
    
        option abortonclose
        # 当服务器负载很高的时候，自动结束掉当前队列处理比较久的链接。注意：如果后端是需要长连接的应用则不应使用这个配置
    
        option dontlognull
        # 启用该项，日志中将不会记录空连接。所谓空连接就是在上游的负载均衡器或者监控系统为了探测该服务是否存活可用时，需要定期的连接或者获取某一固定的组件或页面，或者探测扫描端口是否在监听或开放等动作被称为空连接；{官方文档中标注，如果该服务上游没有其他的负载均衡器的话，建议不要使用该参数，因为互联网上的恶意扫描或其他动作就不会被记录下来}
    
        option httpclose
        # 这个参数我是这样理解的：使用该参数，每处理完一个request时，haproxy都会去检查http头中的Connection的值，如果该值不是close，haproxy将会将其删除，如果该值为空将会添加为：Connection: close。使每个客户端和服务器端在完成一次传输后都会主动关闭TCP连接。与该参数类似的另外一个参数是“option forceclose”，该参数的作用是强制关闭对外的服务通道，因为有的服务器端收到Connection: close时，也不会自动关闭TCP连接，如果客户端也不关闭，连接就会一直处于打开，直到超时。
    
        contimeout 5000
        # 设置成功连接到一台服务器的最长等待时间，默认单位是毫秒，新版本的haproxy使用timeout connect替代，该参数向后兼容
    
        clitimeout 3000
        # 设置连接客户端发送数据时的成功连接最长等待时间，默认单位是毫秒，新版本haproxy使用timeout client替代。该参数向后兼容
    
        srvtimeout 3000
        # 设置服务器端回应客户度数据发送的最长等待时间，默认单位是毫秒，新版本haproxy使用timeout server替代。该参数向后兼容
    
    listen status # 定义一个名为status的部分
    
        bind 0.0.0.0:1080
        # 定义监听的套接字/地址/端口
    
        mode http
        # 定义为HTTP模式
    
        log global
        # 继承global中log的定义
    
        stats refresh 30s
        # stats是haproxy的一个统计页面的套接字，该参数设置统计页面的刷新间隔为30s
    
        stats uri /admin?stats
        # 设置统计页面的uri为/admin?stats
    
        stats realm Private lands
        # 设置统计页面认证时的提示内容
    
        stats auth admin:password
        # 设置统计页面认证的用户和密码，如果要设置多个，另起一行写入即可
    
        stats hide-version
        # 隐藏统计页面上的haproxy版本信息
    
    frontend http_80_in # 定义一个名为http_80_in的前端部分
    # 在 haproxy 的术语中，frontend 表示的是监听套接字，用于等待客户端的连接。
        bind 0.0.0.0:80
        # http_80_in定义前端部分监听的套接字
    
        mode http
        # 定义为HTTP模式
    
        log global
        # 继承global中log的定义
    
        option forwardfor
        # 启用X-Forwarded-For，在requests头部插入客户端IP发送给后端的server，使后端server获取到客户端的真实IP
    
        acl static_down nbsrv(static_server) lt 1
        # 定义一个名叫static_down的acl，当backend static_sever中存活机器数小于1时会被匹配到
    
        acl php_web url_reg /*.php$
        #acl php_web path_end .php
        # 定义一个名叫php_web的acl，当请求的url末尾是以.php结尾的，将会被匹配到，上面两种写法任选其一
        acl static_web url_reg /*.(css|jpg|png|jpeg|js|gif)$
        #acl static_web path_end .gif .png .jpg .css .js .jpeg
        # 定义一个名叫static_web的acl，当请求的url末尾是以.css、.jpg、.png、.jpeg、.js、.gif结尾的，将会被匹配到，上面两种写法任选其一
    
        use_backend php_server if static_down
        # 如果满足策略static_down时，就将请求交予backend php_server
        use_backend php_server if php_web
        # 如果满足策略php_web时，就将请求交予backend php_server
        use_backend static_server if static_web
        # 如果满足策略static_web时，就将请求交予backend static_server
    
    backend php_server #定义一个名为php_server的后端部分
    
        mode http
        # 设置为http模式
    
        balance source
        # 设置haproxy的调度算法为源地址hash。注意：如果代理的是缓存服务器则建议设置为uri模式
    
        cookie SERVERID
        # 允许向cookie插入SERVERID，每台服务器的SERVERID可在下面使用cookie关键字定义
    
        option httpchk GET /test/index.php
        # 开启对后端服务器的健康检测，通过GET /test/index.php来判断后端服务器的健康情况
    
        server nginx_server_1 192.168.0.95:80 cookie 1 check inter 2000 rise 3 fall 3 weight 2
        server nginx_server_2 192.168.0.88:80 cookie 2 check inter 2000 rise 3 fall 3 weight 1
        server nginx_server_bak 192.168.0.33:80 cookie 3 check inter 1500 rise 3 fall 3 backup
        # server语法：server [:port] [param*]
        # server:       使用server关键字来设置后端服务器；
        # php_server_1：为后端服务器所设置的内部名称[php_server_1]，该名称将会呈现在日志或警报中、后端服务器的IP地址，支持端口映射[10.12.25.68:80]
        # cookie 1： ## 错误参数##      指定该服务器的SERVERID为1[cookie 1]
        # check：       接受健康监测[check]、监测的间隔时长，单位毫秒[inter 2000]
        # rise 3：      监测正常多少次后被认为后端服务器是可用的[rise 3]
        # fall 3：      监测失败多少次后被认为后端服务器是不可用的[fall 3]
        # weight 2：    分发的权重[weight 2]
        # backup：      最后为备份用的后端服务器，当正常的服务器全部都宕机后，才会启用备份服务器[backup]
    
    backend static_server
        mode http
        option httpchk GET /test/index.html
        server static_server_1 10.12.25.83:80 cookie 3 check inter 2000 rise 3 fall 3
    
    ```

## 相关链接
  - [haproxy配置文件详解和ACL功能](https://www.cnblogs.com/f-ck-need-u/p/8502593.html)
  - [官方文档](https://cbonte.github.io/haproxy-dconv/1.8/intro.html)
