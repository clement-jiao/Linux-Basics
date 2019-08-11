##安装Alpine Linux实例

##AlpineLinux介绍

>Alpine 的意思是“高山的”，比如 Alpine plants高山植物，Alpine skiing高山滑雪、the alpine resort阿尔卑斯山胜地。
>Alpine Linux 网站首页注明“Small！Simple！Secure！Alpine Linux is a security-oriented, lightweight Linux distribution based on musl libc and busybox.”概括了以下特点：

  - 小巧：基于Musl libc和busybox，和busybox一样小巧，最小的Docker镜像只有5MB；
  - 安全：面向安全的轻量发行版；
  - 简单：提供APK包管理工具，软件的搜索、安装、删除、升级都非常方便。
  - 适合容器使用：由于小巧、功能完备，非常适合作为容器的基础镜像。

###准备工作

下载 Alpine Linux 镜像文件并挂载之虚拟机 [alpine-virt-3.10.1-x86_64.iso](https://www.alpinelinux.org/downloads/)

###开始安装Alpine Linux
  - [Google.com](Google.com)
  - [安装Alpine Linux](https://ncc0706.github.io/2018/02/08/install-alpine-linux/)
  - [安装Alpine Linux实例](https://unixetc.com/post/vmware-installs-alpine-linux-instance/)


###镜像源配置
>在安装时可以选择apk源，如果被跳过可以通过以下方式更换

- 官方镜像
  官方镜像列表：http://rsync.alpinelinux.org/alpine/MIRRORS.txt
- 国内镜像源
  清华TUNA镜像源：[https://mirror.tuna.tsinghua.edu.cn/alpine/](https://mirror.tuna.tsinghua.edu.cn/alpine/)
  中科大镜像源：[http://mirrors.ustc.edu.cn/alpine/](http://mirrors.ustc.edu.cn/alpine/)
  阿里云镜像源：[http://mirrors.aliyun.com/alpine/](http://mirrors.aliyun.com/alpine/)
- 替换apk源
  sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
  [tuna传送门>>>](https://mirrors.tuna.tsinghua.edu.cn/help/alpine/)

###apk包管理命令

Alpine与其他Linux发行版不同使用的是apk进行包管理，通过apk --help命令查看完整的包管理命令。
下面列举常用命令：

- ```apk update：从远程镜像源中更新本地镜像源索引```

  >update 命令会从各个镜像源列表下载 apkindex.tar.gz 并存储到本地缓存，一般在 `/var/cache/apk/(Alpine在该目录下)`、 `/var/lib/apk/` 、`/etc/apk/cache/`下。

- `add：安装packages并自动解决依赖关系`

  >add命令从仓库中安装最新软件包，并自动安装必须的依赖包,也可以从第三方仓库添加软件包。

  ```bash
  $ apk add openssh openntp vim       # 安装软件包
  $ apk add --no-cache mysql-client   # 不从本地缓存安装
  $ apk add docker --update-cache --repository http://mirrors.ustc.edu.cn/alpine/v3.4/main/ --allow-untrusted  # 指定源安装
  ```

- `add：安装指定版本软件包`

  ```bash
  $ apk add asterisk=1.6.0.21-r0
  $ apk add 'asterisk<1.6.1'    # 小于此版本
  $ apk add 'asterisk>1.6.1'    # 大于此版本
  ```

- `del：卸载并删除package`
  ```bash
  $ apk del openssh openntp vim # 直接指定某个软件包
  ```

- `upgrade：升级当前已安装的软件包`
  >upgrade 命令升级系统已安装的所以软件包（一般包括内核），当然也可指定仅升级部分软件包（通过 -u 或 –upgrade 选择指定）

  ```bash
  $ apk update    #更新最新本地镜像源
  $ apk upgrade   #升级软件
  $ apk add --upgrade busybox   #指定升级部分软件包
```

- `search：搜索软件包`
  >search命令搜索可用软件包，-v参数输出描述内容，支出通配符，-d或–description参数指定通过软件包描述查询。
  ```bash
  $ apk search                  #查找所以可用软件包
  $ apk search -v               #查找所以可用软件包及其描述内容
  $ apk search -v 'acf*'        #通过软件包名称查找软件包
  $ apk search -v -d 'docker'   #通过描述文件查找特定的软件包
  ```

- `info：列出PACKAGES或镜像源的详细信息`
  ```bash
  $ apk info                      #列出所有已安装的软件包
  $ apk info -a zlib              #显示完整的软件包信息
  $ apk info --who-owns /sbin/lbu #显示指定文件属于的包
  ```

###init系统
Alpine Linux使用的是Gentoo一样的OpenRCinit系统.
以下命令可用于管理init系统：
- `rc-update`
  >主要用于不同运行级增加或者删除服务。

- rc-update语法格式
  ```bash
  Usage: rc-update [options] add <service> [<runlevel>...]
    or: rc-update [options] del <service> [<runlevel>...]
    or: rc-update [options] [show [<runlevel>...]]

  Options: [ asuChqVv ]
    -a, --all                         Process all runlevels
    -s, --stack                       Stack a runlevel instead of a service
    -u, --update                      Force an update of the dependency tree
    -h, --help                        Display this help output
    -C, --nocolor                     Disable color output
    -V, --version                     Display software version
    -v, --verbose                     Run verbosely
    -q, --quiet                       Run quietly (repeat to suppress errors)
  ```

- rc-update 使用实例
  ```bash
  $ rc-update add docker boot #增加一个服务
  $ rc-update del docker boot #删除一个服务
  ```

- `rc-status`
  >rc-status 主要用于运行级的状态管理。

- `rc-status语法格式`
  ```bash
  Usage: rc-status [options] <runlevel>...
    or: rc-status [options] [-a | -c | -l | -r | -s | -u]

  Options: [ aclrsuChqVv ]
    -a, --all                         Show services from all run levels
    -c, --crashed                     Show crashed services
    -l, --list                        Show list of run levels
    -r, --runlevel                    Show the name of the current runlevel
    -s, --servicelist                 Show service list
    -u, --unused                      Show services not assigned to any runlevel
    -h, --help                        Display this help output
    -C, --nocolor                     Disable color output
    -V, --version                     Display software version
    -v, --verbose                     Run verbosely
    -q, --quiet                       Run quietly (repeat to suppress errors)
  ```
- rc-status 使用实例
  ```bash
  $ rc-status  #检查默认运行级别的状态
  $ rc-status -a #检查所有运行级别的状态
  ```
- rc-service
>rc-service主用于管理服务的状态
- rc-service语法格式
  ```
  Usage: rc-service [options] [-i] <service> <cmd>...
    or: rc-service [options] -e <service>
    or: rc-service [options] -l
    or: rc-service [options] -r <service>

  Options: [ e:ilr:INChqVv ]
    -e, --exists <arg>                tests if the service exists or not
    -i, --ifexists                    if the service exists then run the command
    -I, --ifinactive                  if the service is inactive then run the command
    -N, --ifnotstarted                if the service is not started then run the command
    -l, --list                        list all available services
    -r, --resolve <arg>               resolve the service name to an init script
    -h, --help                        Display this help output
    -C, --nocolor                     Disable color output
    -V, --version                     Display software version
    -v, --verbose                     Run verbosely
    -q, --quiet                       Run quietly (repeat to suppress errors)
  ```
- rc-service使用实例
  ```bash
  $ rc-service sshd start     #启动一个服务。
  $ rc-service sshd stop      #停止一个服务。
  $ rc-service sshd restart   #重启一个服务。
  ```
- `openrc`
  >主要用于管理不同的运行级。
- openrc语法格式
  ```bash
  Usage: openrc [options] [<runlevel>]

  Options: [ a:no:s:SChqVv ]
    -n, --no-stop                     do not stop any services
    -o, --override <arg>              override the next runlevel to change into
                                      when leaving single user or boot runlevels
    -s, --service <arg>               runs the service specified with the rest
                                      of the arguments
    -S, --sys                         output the RC system type, if any
    -h, --help                        Display this help output
    -C, --nocolor                     Disable color output
    -V, --version                     Display software version
    -v, --verbose                     Run verbosely
    -q, --quiet                       Run quietly (repeat to suppress errors)
  ```
  - Alpine Linux可用的运行级:
    >- default
     - sysinit
     - boot
     - single
     - reboot
     - shutdown
- openrc 使用实例
  ```bash
  $ openrc single   #更改为single运行级
  ```
- 其它指令
  ```bash
  $ reboot      #重启系统，类似于shutdown -r now。
  $ halt        #关机，类似于shutdown -h now。
  $ poweroff    #关机
  ```
