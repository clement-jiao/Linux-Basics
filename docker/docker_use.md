# Docker

## 总体架构

<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\docker-architecture.jpg" alt="../_images/docker-architecture.jpg" style="zoom:50%;" />

docker 是一个 C/S 模式的架构，后端是一个松耦合架构，模块各司其职。

1. 用户是使用 Docker Client 与 Docker Daemon 建立通讯，并发送请求给后者。
2. Docker Daemon 作为 Docker 架构中的主体部分，首先提供 Server 的功能使其可以接收 Docker Client 的请求。
3. Engine 执行 Docker 内部的一系列工作，每一项工作都是以一个 Job 的形式的存在。
4. Job 的运行过程中，当需要容器镜像时，则从 Docker Registry 中下载镜像，并通过镜像管理驱动 graphdriver 将下载镜像以 Graph 的形式存储；
5. 当需要为 Docker 创建网络环境时，通过网络管理驱动 networkdriver 创建并配置 Docker 容器网络环境；
6. 当需要限制 Docker 容器运行资源或执行用户指令等操作时，则通过 execdriver 来完成。
7. libcontainer 是一项独立的容器管理包，networkdriver以及execdriver都是通过libcontainer来实现具体对容器进行的操作。

### Docker Client [发起请求]

1. Docker Client 是和 Docker Daemon 建立通信的客户端。用户使用的可执行文件为 docker（类似可执行脚本的命令），docker 命令后接参数的形式来实现一个完整的请求命令（例如 docker images，docker 为命令可不变，images 为参数可变）。
2. Docker Client 可以通过以下三种方式和 Docker Daemon 建立通信
   - `tcp://host:port`
   - `unix://path_to_socket`
   - `fd://sockerfd`
3. Docker Client 发送容器管理请求后，由 Docker Daemon 接受并处理请求，当 Docker Client 接收到返回的请求响应并简单处理后，Docker Client 一次完整的生命周期就结束了。【一次完整的请求：发送请求→处理请求→返回结果】，于传统的C/S架构请求流程并无不同。

### Docker Daemin [后台守护进程]

**Docker Daemon 的架构图**
<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\docker-daemon.jpg" alt="../_images/docker-daemon.jpg" style="zoom:50%;" />

#### docker Server [调度分发请求]

**Docker Server 的架构图**
<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\docker-server.jpg" alt="../_images/docker-server.jpg" style="zoom:50%;" />

1. Docker Server 相当于 C/S 架构的服务端。功能为接收并调度分发 Docker Client 发送的请求。接收请求后，Server 通过路由于分发调度，找到相应的 Handler 并执行请求。

2. 在 Docker 启动过程中，通过包 gorilla/mux，创建一个 mux.Router，提供请求的路由功能。在 Golang 中，gorilla/mux 是一个强大的 URL 路由器以及调度分发器。该 mux.Router 中添加了众多的路由项，每一个路由项由 HTTP 请求方法（PUTPOSTGETDELETE）、URL、Handler 三部分组成

3. 创建完 mux.Router 之后，Docker 将 Server 的监听地址以及 mux.Router 作为参数，创建一个 httpSrv=http.Server{}，最终执行 httpSrv.Server() 为请求服务。

4. 在 Server 的服务过程中，Server 在 Listener 上接受 Docker Client 的访问请求，并创建一个全新的 goroutine 来服务该请求。在 goroutine 中，首先读取请求内容，然后做解析工作，接着找到相应的路由项，随后调用相应的 Handler 来处理该请求，最后 Handler 处理完请求之后回复该请求。

#### Engine
   1. Engine 是 Docker 架构中的运行引擎，同时也是 Docker 运行的核心模块。它扮演 Docker container 存储仓库的角色，并且通过执行 job 的方式来操纵管理这些容器。
   2. 在 Engine 数据结构的设计于实现过程中，有一个 handler 对象。该 handler 对象存储的都是关于众多特定 job 的 handler 处理访问。举例说明，Engine 的 handler 对象中有一项为：`{"create": daemin.ContainerCreate,}` ，则说明当名为”create“的job在运行是，执行的是 daemon.ContainerCreate 的 handler。

#### job
1. 一个 Job 可以认为是 Docker 架构中 Engine 内部最基本的工作执行单元。Docker 可以做的每一项工作，都可以抽象为一个 job。例如：在容器内部运行一个进程，这是一个 job；创建一个新的容器，这是一个 job。Docker Server 的运行过程也是一个 Job，名为 serverapi。
2. Job 的设计者，把 Job 设计的与 Unix 进程相仿。比如说： job 有一个名称，有参数，有环境变量，有标准的输入输出，有错误处理，有返回状态等。

### Docker Registry [镜像注册中心]

1. Docker Registry 是一个存储容器镜像的仓库（注册中心），可以理解为云端镜像仓库，按 repository 来分类，docker pull 按照 [repository]:[tag] 来精确定义一个 image。
2. 在 Docker 的运行过程中，Docker Daemon 会与 Docker Registry 通信，并实现搜索镜像、下载镜像、上传镜像三个功能，这三个功能对应的 job 名称分别为 “search”，“pull” 与 “push”
3. 可分为公有仓库（docker hub）和私有仓库

### Graph [docker 内部数据库]

**Graph 的架构图**
<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\graph-architecture.jpg" alt="../_images/graph-architecture.jpg" style="zoom:50%;" />

1. Repository

   1. 已下载镜像的保管者（包括下载镜像和 dockerfile 构建的镜像）
   2. 一个 repository 表示某类镜像的仓库（例如 Ubuntu），同一个 repository 内的镜像用 tag 来区分（表示同一类镜像的不同标签或版本）。一个 Registry 包含多个 repository，一个 repository 包含同类型的多个 image。
   3. 镜像的存储类型有 aufs，devicemapper，Btrfs，vfs 等。其中 centos 系统使用 devicemapper 的存储类型。
   4. 同时在 Graph 的本地目录中，关于每一个的容器镜像，具体存储的信息有：该容器镜像的元数据，容器镜像的大小信息，以及该容器镜像所代表的具体 rootfs。

2. GraphDB

   1. 已下载容器镜像之间关系的记录者。
   2. GraphDB 是一个构建在 SQLite 之上的小型图形数据库，实现了节点的命名以及节点之间关联关系的记录。

### Driver [执行部分]

Driver 是 Docker 架构中的驱动模块。通过 Driver 驱动，Docker 可以实现对 Docker 容器执行环境的定制。即 Graph 负责镜像的存储，Driver 负责容器的执行。
#### graphdriver
**graphdriver 架构图**
<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\graphdriver-16412047478352.jpg" alt="../_images/graphdriver.jpg" style="zoom:50%;" />

 1. graphdriver 主要用于完成容器镜像的管理，包括存储与获取。
 2. 存储：docker pull 下载的镜像由 graphdriver 存储导本地的指定目录（Graph 中）。
 3. 获取：docker run (create) 用镜像来创建容器的时候由 graphdriver 到本地 Graph 中获取镜像。

#### networkdriver

**networkdriver 的架构图**

<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\networkdriver.jpg" alt="../_images/networkdriver.jpg" style="zoom:50%;" />

 1. networkdriver 的用途是完成docker容器网络环境的配置，其中包括：
   - Docker 启动时为 Docker 环境创建网桥
   - Docker 容器创建时为其创建专属虚拟网卡设备
   - Docker 容器分配IP、端口并与宿主机做端口映射，设置容器防火墙策略等。

#### execdriver

**execdriver 的结构图**
<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\execdriver-16412047598096.jpg" alt="../_images/execdriver.jpg" style="zoom:50%;" />

1. execdriver 作为 Docker 容器的执行驱动，负责创建容器运行命名空间，负责容器资源使用的统计与限制，负责容器内部进程的真正运行等。
2. 现在 execdriver 默认使用 native 驱动，不依赖于 LXC。

### libcontainer [函数库]

**libcontainer 的架构图**

<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\networkdriver.jpg" alt="../_images/networkdriver.jpg" style="zoom:50%;" />

1. libcontainer 是 Docker 架构中一个使用 Go 语言设计实现的库，设计初衷时希望该库可以不依靠任何依赖，直接访问内核中于容器相关的 API。
2. Docker 可以直接调用 libcontainer，而最终操作容器的 namespace、cgroups、apparmor、网络设备以及防火墙规则等。
3. libcontainer 提供了一整套标准的接口来满足上层对容器管理的需求。或者说，libcontainer 屏蔽了 Docker 上层对容器的直接管理。

### Docker container [服务交付的最终形式]

**container 架构**

<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\container-164123257116517.jpg" alt="../_images/container.jpg" style="zoom:50%;" />

1. Docker container（Docker 容器）是Docker架构中服务交付的最终体现形式

2. Docker 按照用户的需求于指令，定制相应的 Docker 容器

   - 用户通过指定容器镜像，使得 Docker 容器可以自定义 rootfs 等文件系统
   - 用户通过指定计算资源的配额，使得 Docker 容器使用指定的计算资源
   - 用户通过配置网络及其安全策略，使得 Docker 容器拥有独立且安全的网络环境
   - 用户通过指定运行的命令，使得 Docker 容器执行指定的工作

## 基础用法

### 安装
#### 依赖的基础环境
64 bits CPU
Linux Kernel 3.10+
Linux Kernel cgroups and namespaces

#### CentOS 7+

“Extras” repository：不建议通过 CentOS 默认仓库安装 Docker，版本过旧

#### Docker Daemon

systemctl start docker.service

推荐使用 daocloud 安装 docker，安装方式详见：[DaoCloud镜像站_DaoCloud道客](https://www.daocloud.io/mirror)

### docker 程序环境

docker 环境配置都可以由 `/etc/docker/daemon.none` 这个文件所控制。docker 安装后默认没有 daemon.none 这个配置文件，需要手工创建。

一般情况下，配置文件 daemin.none 中配置的项目参数，在启动参数中同样适用，有些可能不一样（具体可以查看官方文档），但需要注意的一点，配置文件中如果已经由摸个配置项，则无法在启动参数中增加，会出现冲突的错误。

Attention

如果在 daemon.none 文件中进行配置，需要 docker 版本高于 1.12.6（在这个版本不生效，1.13.1 以上是生效的）

- 指定网桥网络
  给 docker0 分配特定的IP地址，并设置子网掩码
```json
{
    "bip": "192.168.199.5/24"
}
```

- 指定网桥网络范围

 限制 docker0 分配给容器的IP的范围。必须是 docker0 所在网络范围内的一个子网，或是由 `--bridge` 指定的网桥的IP所在网络范围内的一个子网。此后，为容器分配IP时就会从这个范围内选择一个可用的IP地址。

```json
{
    "fixed-cidr": "10.20.0.0/16",
    "fixed-cide-v6": "2001:db8::/64"
}
```

- 最大传输单元

覆盖 docker0 默认的最大传输单元
```json
{
    "mtu": 1500
}
```

- 指定 DNS
```json
{
    "dns": ["8.8.8.8", "8.8.4.4"]
}
```

- 指定监听模式
```json
{
    "hosts": ["tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"]
}
```

- 镜像加速器

```json
// 配置单个
{
    "registry-mirrors": ["https://registry.docker-cn.com"]
}

// 配置多个
{
    "registry-mirrors": ["https://registry.docker-cn.com", "https://docker.mirrors.ustc.edu.cn"]
}
```

- 日志

  log-level 的有效值包括：
  - debug
  - info
  - warn
  - error
  - fatal

```json
{
    "debug": true,
    "log-level": "info"
}
```

指定日志格式、大小和数量等。

```json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "5m",
        "max-file": "5"
    }
}
```

- 监控 Prometheus

  https://docs.docker.com/engine/admin/prometheus/#configure-docker

  ```
  {
   "metrics-addr": "127.0.0.1:9323",
   "experimental": true
  }
  ```

- 保持容器在线

  https://docs.docker.com/engine/admin/live-restore/#enable-the-live-restore-option

  当 dockerd 进程死掉后，依旧保持容器存活。

  ```
  {
   "live-restore": true
  }
  ```

  Linux 重载 docker daemon

  ```
  $ sudo kill -SIGHUP $(pidof dockerd)
  ```

- 信任私有仓库地址

  docker 默认只信任 HTTPS 协议私有镜像仓库，如果搭建内网私有镜像仓库使用 HTTP 协议，需要指定信任仓库。

  ```
  {
   "insecure-registries": [ "10.10.172.203:5000" ]
  }
  ```

- 设置 镜像、容器、卷 存放目录和驱动

  https://docs.docker.com/engine/admin/systemd/#runtime-directory-and-storage-driver

  下述两个参数可以单独使用

  ```
  {
   "graph": "/mnt/docker-data",
   "storage-driver": "overlay"
  }
  ```

  graph 设置存放目录 —— Docker Root Dir /mnt/docker-data storage-driver 设置存储驱动 —— Storage Driver overlay

- user namespace remap

  https://docs.docker.com/engine/security/userns-remap/#enable-userns-remap-on-the-daemon

  安全设置：用户空间重映射

  userns-remap 的值可以是 如果值字段 只有 一个值，那么该字段表示组。如果需要同时指定 用户和组，需要使用 冒号 分割，格式为 用户:组

  - 组

  - 用户:组

  - 组 或 用户 的值可以是组或用户的 名称 或 ID

    - testuser
    - testuser:testuser
    - 1001
    - 1001:1001
    - testuser:1001
    - 1001:testuser

  ```
  {
      "userns-remap": "testuser"
  }

  // 或同时指定 用户和组，且使用 名称和ID
  {
      "userns-remap": "testuser:1001"
  }
  ```

  ```
  $ dockerd --userns-remap="testuser:testuser"
  ```

  Note

  userns-remap 使用不多，但并不是不重要。目前不是默认启用的原因时因为一些应用会假定 uid 0 的用户拥有特殊能力，从而导致假定失败，然后报错退出。所以如果要启用 user id remap，你要充分测试一下。但是启用 uid remap 的安全性提高是明显的。

配置完成后我们可以通过命令 `docker info` 查看 docker 详细信息

### 常用操作

| command    | content                                                      | subobject | subobject content                                            |
| ---------- | ------------------------------------------------------------ | --------- | ------------------------------------------------------------ |
| config     | Manage Docker configs                                        | create    | Create a configuration file from a file or STDIN as content  |
| inspect    | Display detailed information on one or more configuration files |           |                                                              |
| ls         | List configs                                                 |           |                                                              |
| rm         | Remove one or more configuration files                       |           |                                                              |
| container  | Manage container                                             | attach    | Attach local standard input, output, and error streams to a running container |
| commit     | Create a new image from a container’s changes                |           |                                                              |
| cp         | Copy files/folders between a container and the local filesystem |           |                                                              |
| create     | Create a new container                                       |           |                                                              |
| diff       | Inspect changes to files or directories on a container’s filesystem |           |                                                              |
| exec       | Run a command in a running container                         |           |                                                              |
| export     | Export a container’s filesystem as a tar archive             |           |                                                              |
| inspect    | Display detailed information on one or more containers       |           |                                                              |
| kill       | Kill one or more running containers                          |           |                                                              |
| logs       | Fetch the logs of a container                                |           |                                                              |
| ls         | List containers                                              |           |                                                              |
| pause      | Pause all processes whitin one or more containers            |           |                                                              |
| port       | List port mappings or a specific mapping for the container   |           |                                                              |
| prune      | Remove all stopped containers                                |           |                                                              |
| rename     | Rename a container                                           |           |                                                              |
| restart    | Restart one or more containers                               |           |                                                              |
| rm         | Remove one or more container                                 |           |                                                              |
| run        | Run a command in a new container                             |           |                                                              |
| start      | Start one or more stopped containers                         |           |                                                              |
| stars      | Display a live stream of container(s) resource usage statistics |           |                                                              |
| stop       | Stop one or more running containers                          |           |                                                              |
| top        | Display the running processes of a containers                |           |                                                              |
| unpause    | Unpause all processes within one or more containers          |           |                                                              |
| update     | Update configuration of one or more containers               |           |                                                              |
| wait       | Block until one or more containers stop, then print their exit codes |           |                                                              |
| image      | Manage images                                                | build     | Build an image from Dockerfile                               |
| history    | Show the history of an image                                 |           |                                                              |
| import     | Import the containers from a tarball to create a filesystem image |           |                                                              |
| inspect    | Display detailed information on onw or more images           |           |                                                              |
| load       | Load an image from a tar archive or STDIN                    |           |                                                              |
| ls         | List images                                                  |           |                                                              |
| prune      | Remove unused images                                         |           |                                                              |
| pull       | Pull an image or a repository from a registry                |           |                                                              |
| push       | Push an image or a repository to a registry                  |           |                                                              |
| rm         | Remove one or more images                                    |           |                                                              |
| save       | Save one or more images to a tar archive (streamed to STDOUT by default) |           |                                                              |
| tag        | Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE        |           |                                                              |
| network    | Manage networks                                              | connect   | Connect a container to a network                             |
| create     | Create a network                                             |           |                                                              |
| disconnect | Disconnect detailed information on one or more networks      |           |                                                              |
| inspect    | Display detailed information on one or more networks         |           |                                                              |
| ls         | List networks                                                |           |                                                              |
| prune      | Remove all unused networks                                   |           |                                                              |
| rm         | Remove one or more networks                                  |           |                                                              |
| node       | Manage Swarm node                                            | deamon    | Demote one or more nodes from manager in the swarm           |
| inspect    | Display detailed information on one or more nodes            |           |                                                              |
| ls         | List nodes in the swarm                                      |           |                                                              |
| promote    | Promote one or more nodes to manager in the swarm            |           |                                                              |
| ps         | List tasks running on one or more nodes, defaults to current node |           |                                                              |
| rm         | Remove one or more nodes from the swarm                      |           |                                                              |
| update     | Update a node                                                |           |                                                              |
| plugin     | Manage plugins                                               | create    | Create a plugin from a rootfs and configuration. Plugin data directory must contain config.json and rootfs directory. |
| disable    | Disable a plugin                                             |           |                                                              |
| enable     | Enable a plugin                                              |           |                                                              |
| inspect    | Display detailed information on one or more plugins          |           |                                                              |
| install    | Install a plugin                                             |           |                                                              |
| ls         | List plugins                                                 |           |                                                              |
| push       | Push a plugin to a registry                                  |           |                                                              |
| rm         | Remove one or more plugin                                    |           |                                                              |
| set        | Change settings for a plugin                                 |           |                                                              |
| upgrade    | Upgrade an existing plugin                                   |           |                                                              |
| secret     | Manage Docker secrets                                        | create    | Create a secret from a file or STDIN as content              |
| inspect    | Display detailed information on onw or more secrets          |           |                                                              |
| ls         | List secrets                                                 |           |                                                              |
| rm         | Remove one or more secrets                                   |           |                                                              |
| service    | Manage service                                               | create    | Create a new service                                         |
| inspect    | Display detailed information on one or more services         |           |                                                              |
| logs       | Fetch the logs of a service or task                          |           |                                                              |
| ls         | List services                                                |           |                                                              |
| ps         | List the tasks of one or more services                       |           |                                                              |
| rm         | Remove one or more services                                  |           |                                                              |
| rollback   | Revert changes to a service’s configuration                  |           |                                                              |
| scale      | Scale one or multiple replicated services                    |           |                                                              |
| update     | Update a service                                             |           |                                                              |
| stack      | Manage Docker stacks                                         | create    | Create a new service                                         |
| inspect    | Display detailed information on one or more services         |           |                                                              |
| logs       | Fetch the logs of a service or task                          |           |                                                              |
| ls         | List services                                                |           |                                                              |
| ps         | List the tasks of one or more services                       |           |                                                              |
| rm         | Remove one or more services                                  |           |                                                              |
| rollback   | Revert changes to a service’s configuration                  |           |                                                              |
| scale      | Scale one or multiple replicated services                    |           |                                                              |
| update     | Update a services                                            |           |                                                              |
| swarm      | Manage Swarm                                                 | ca        | Display and rotate the root CA                               |
| init       | Initialize a swarm                                           |           |                                                              |
| join       | Join a swarm as a node and/or manager                        |           |                                                              |
| join-token | Manager join tokens                                          |           |                                                              |
| leave      | Leave the swarm                                              |           |                                                              |
| unlock     | Unlock swarm                                                 |           |                                                              |
| unlock-key | Manage the unlock key                                        |           |                                                              |
| update     | Update the swarm                                             |           |                                                              |
| system     | Manage Docker                                                | df        | Show docker disk usage                                       |
| events     | Get real time events from the server                         |           |                                                              |
| info       | Display system-wide information                              |           |                                                              |
| prune      | Remove unused data                                           |           |                                                              |
| trust      | Manage trust on Docker images (experimental)                 | key       | Manage keys for signing Docker images (experimental)         |
| signer     | Manage entities who can sign Docker images (experimental)    |           |                                                              |
| inspect    | Return low-level information about keys and signatures       |           |                                                              |
| revoke     | Remove trust for an image                                    |           |                                                              |
| sign       | Sign an image                                                |           |                                                              |
| view       | Display detailed information about keys and signatures       |           |                                                              |
| volume     | Manage volumes                                               | create    | Create a volume                                              |
| inspect    | Display detailed information on one or more volumes          |           |                                                              |
| ls         | List volumes                                                 |           |                                                              |
| prune      | Remove all unused volumes                                    |           |                                                              |
| rm         | Remove one or more volumes                                   |           |                                                              |

### 状态转换

<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\docker_event_stats-164123250721415.jpg" alt="../_images/docker_event_stats.jpg" style="zoom: 80%;" />

## 网络模型

当你开始大规模使用 Docker 时，你会发现需要了解很多关于网络的知识。Docker 容器需要运行在一台宿主机上，可以是一台物理机（on-premise 数据中心的裸金属服务器），也可以是 on-prem 或云上的一台虚拟机。

### 简单的 Docker 架构

宿主机和容器的关系是 `1:N` ，这意味着一台宿主机上可以运行多个容器。例如，从 Facebook 的报告来看，取决于机器的能力，每台宿主机上平均可以运行 10 到 40 个容器。另一个数据是：在 Mesosphere，我们发现，在裸金属服务器上的各种负载测试中，每台宿主机上不超过 250 个容器是可能的。

无论你是在单主机上进行部署，还是在集群上部署，你总得和网络打交道：

- 对于大多数单主机部署来说，问题归结于是使用共享卷进行数据交换，还是使用网络（基于 HTTP 或者其他的）进行数据交换。尽管 Docker 数据卷很容易使用，但也引入了紧耦合，这意味着很难将单主机部署转换为多主机部署。自然地，共享卷的优势是速度。
- 在多主机部署中，你需要考虑两个方面：单主机上的容器之间如何通信和多主机之间的通信路径是怎样的。性能考量和安全方面都有可能影响你的设计决定。多主机部署通常是很有必要的，原因是单主机的能力有限，也可能是因为需要部署分布式系统，例如 Apache Spark、HDFS 和 Cassandra。

Note

分布式系统的数据本地化（Distributed Systems and Data Locality）

使用分布式系统（计算或存储）的基本想法是想从并行处理中获利，通常伴随着数据本地化。数据本地化，我指的是将代码转移到数据所在地的原则，而不是传统的、其他的方式。考虑以下的场景：如果你的数据集是 TB 级的，而代码是 MB 级的，那么在集群中移动代码此传输 TB 级数据更高效。除了可以并行处理数据之外，分布式系统还可以提供容错性，因为系统中的一部分可以相对独立地工作。

简单的说，Docker 网络是原生的容器 SDN 解决方案。总而言之，Docker 网络有四种模式：桥接模式，主机模式，容器模式和无网络模式。我们会详细地讨论主机上的各种网络模式。

![../_images/four-network-container-archetypes.png](C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\four-network-container-archetypes.png)

```bash
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
94bb253e0ddc        bridge              bridge              local
59d9038bfac5        host                host                local
920274f49a70        none                null                local
```

### bridge 模式网络

在该模式中，docker 守护进程创建了一个虚拟以太网桥 `docker0` ，附加在其上的任何网卡之间都能自动转发数据包。默认情况下，守护进程会创建一对对等接口，将其中一个接口设置为容器的 eth0 接口，另一个接口放置在宿主机的命名空间中，从而将宿主机上的所有容器都链接到这个内部网络上。同时，守护进程还会从网桥的似有地址空间中分配一个IP地址和子网给该容器。

```bash
$ docker container run --name=web01 --detach --publish-all --net=bridge nginx:1.14-alpine

$ docker container ps
CONTAINER ID IMAGE      COMMAND                 CREATED     STATUS     PORTS          NAMES
7f056ef642b7 nginx:1.14 "nginx -g 'daemon ..."  6 days ago  Up 4 days  32768->80/tcp  web01

$ docker container inspect web01
...
"NetworkSettings": {
    "Bridge": "",
    "SandboxID": "56cb1f03f8eda8c1ce73a764eb36794cd87dbf3cae399d2220b623b1f711678a",
    "HairpinMode": false,
    "LinkLocalIPv6Address": "",
    "LinkLocalIPv6PrefixLen": 0,
    "Ports": {
        "80/tcp": [
            {
                "HostIp": "0.0.0.0",
                "HostPort": "32768"
            }
        ]
    },
    "SandboxKey": "/var/run/docker/netns/56cb1f03f8ed",
    "SecondaryIPAddresses": null,
    "SecondaryIPv6Addresses": null,
    "EndpointID": "11ede3c1709ded6a68dd5c4a4607feb5eec780534a8882580b9bc30c79c14b7a",
    "Gateway": "172.17.0.1",
    "GlobalIPv6Address": "",
    "GlobalIPv6PrefixLen": 0,
    "IPAddress": "172.17.0.2",
    "IPPrefixLen": 16,
    "IPv6Gateway": "",
    "MacAddress": "02:42:ac:11:00:02",
    "Networks": {
        "bridge": {
            "IPAMConfig": null,
            "Links": null,
            "Aliases": null,
            "NetworkID": "94bb253e0ddcd0f2f7b0037bc51c537d2bdcd5d5a156963fbf1c611c37ae807d",
            "EndpointID": "11ede3c1709ded6a68dd5c4a4607feb5eec780534a8882580b9bc30c79c14b7a",
            "Gateway": "172.17.0.1",
            "IPAddress": "172.17.0.2",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "MacAddress": "02:42:ac:11:00:02",
            "DriverOpts": null
        }
    }
}
...
```

查看 bridge 网桥与容器的接口

```
$ yum -y install bridge-utils
$ brctl show
bridge name bridge id               STP enabled     interfaces
docker0             8000.02428b0967f8       no              veth20f8faa
```

因为 bridge 模式是 Docker 的默认设置，所以你也可以使用 `docker container run --detach --publish-all --name=web01 nginx:1.14-alpine` 。如果你没有使用 –publish-all（发布该容器暴露的所有端口）或者 –publish host_port:container_port（发布某个特定的端口），IP 数据包就不能从宿主机之外路由到容器中。

<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\container_network_mode_bridge.png" alt="../_images/container_network_mode_bridge.png" style="zoom: 67%;" />

### host 模式

该模式将禁用 Docker 容器的网络隔离。因为容器共享了宿主机的网络命名空间，直接暴露再公共网络之中。因此，你需要通过端口映射（port mapping）来进行协调。

```bash
$ docker container run --detach --name=web01 --publish-all --net=host nginx:1.14-alpine
882db350e02b9922bd911ce9d1b08cfc085cc7baf1dee2a75fbfeae1fae12cfd

$ ip addr | grep -A 2 eth0:
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
link/ether d0:0d:b5:97:40:9f brd ff:ff:ff:ff:ff:ff
inet 172.19.135.14/24 brd 172.19.135.255 scope global dynamic eth0

$ docker container ps
CONTAINER ID  IMAGE        COMMAND                  CREATED     STATUS    PORTS     NAMES
c5a4c0105f22  nginx:1.14   "nginx -g 'daemon ..."   2 days ago  2 days              web01
```

我们进入容器内部查看网卡信息

```bash
# docker container exec --interactive --tty web01 /bin/sh
# 可以简写为 docker  exec  -i -t   web01 sh
/ $ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
    valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether d0:0d:b5:97:40:9f brd ff:ff:ff:ff:ff:ff
    inet 172.19.135.14/24 brd 172.19.135.255 scope global dynamic eth0
    valid_lft 314753218sec preferred_lft 314753218sec
    inet6 fe80::d20d:b5ff:fe97:409f/64 scope link
    valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN
    link/ether 02:42:8b:09:67:f8 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global docker0
    valid_lft forever preferred_lft forever
    inet6 fe80::42:8bff:fe09:67f8/64 scope link
    valid_lft forever preferred_lft forever
/ $ exit
```

我们可以从上例中看到：容器和宿主机具有相同的IP地址  `172.19.135.14`

在下图中我们可以看到：当使用 host 模式网络时，容器实际上继承了宿主机的IP地址。该模式比 bridge 模块更快（因为没有路由开销），但是它将容器直接暴露在公共网络中，是有安全隐患的。

![../_images/Docker_network_mode_host.png](C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\Docker_network_mode_host.png)

### container 模式网络

该模式会重用另一个容器的网络名称空间。通常来说，当你想要自定网络栈时，该模式时很有用的。实际上，该模式也是 Kubernetes 使用的网络模式。

```
# docker container run --detach --publish-all --net=bridge --name=web01 nginx:1.14-alpine
07d43ffe5f341cb10a46c3be9c71a05ffa5b5004aedb38a6cc975705855b8dd9
# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                   NAMES
07d43ffe5f34        nginx:1.14-alpine   "nginx -g 'daemon ..."   7 seconds ago       Up 6 seconds        0.0.0.0:32769->80/tcp   web01
# docker exec --tty --interactive web01 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    valid_lft forever preferred_lft forever
6: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 scope global eth0
    valid_lft forever preferred_lft forever
# docker run --interactive --tty --net=container:web01 ubuntu:14.04 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    valid_lft forever preferred_lft forever
6: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 scope global eth0
    valid_lft forever preferred_lft forever
```

结果显示：第二个容器使用 `--net=container` 参数，因此和第一个容器 `web01` 具有相同的ip地址 `172.17.0.2`

### none 模式网络

该模式将容器放置在它自己的网络中，但是并不进行任何配置。实际上，该模式关闭了容器的网络功能，在以上两种情况下时有用的：容器并不需要网络（例如只需要写磁盘卷的批处理任务）；你希望自定义网络。

```bash
$ docker container run --detach --publish-all --net=none nginx:1.14-alpine
90e19ccb6938b12c366022411a93f25ecb05a7f6b49dd640bb5a0703068076ab
$ docker ps
CONTAINER ID  IMAGE       COMMAND                 CREATED     STATUS  PORTS  NAMES
90e19ccb6938  nginx:1.14  "nginx -g 'daemon ..."  1 days ago  1 days         gracious_bartik
$ docker container inspect gracious_bartik | grep IPAddress
        "SecondaryIPAddresses": null,
        "IPAddress": "",
                "IPAddress": "",
```

在上面的例子中可以看到，恰如我们所料，网络没有任何配置。

### 其他网络话题

- 分配IP地址

  > 频繁大量的创建和销毁容器时，手动分配IP地址是不能接受的。bridge 模式可以在一定程度上解决这个问题。为了防止本地网络上的 ARP 冲突，Docker Daemon 会根据分配的IP地址生成一个随机的 MAC 地址。

- 分配端口

  > 你会发现有两大阵营：固定端口分配（fixed-port-allocation）和动态端口分配（dynamically-port-allocation）。每个服务或者应用可以有各自的分配方法，也可以是作为全局的策略，但是你必须做出自己的判断和决定。请记住，bridge 模式中，Docker 会自动分配 UDP 或 TCP 端口，并使其可路由。

- 网络安全

  > Docker 可以开启容器间通信（意味着默认配置 `--icc=true` ），也就是说，宿主机上的所有容器可以不接受任何限制地相互通讯，这可能导致拒绝服务攻击。进一步地，Docker 可以通过 `--ip_forward` 和 `--iptables` 两个选项控制容器间、容器和外部世界的通信。你应该了解这些选项的默认值，并让网络组根据公司策略设置 Docker 进程。
  >
  > 另一个网络安全方面是线上加密（on-the-wire encryption），通常是指 RFC 5246 中定义的 TLS/SSL。

### 跨主机网络

在微服务架构中，多个服务是通过服务注册中心进行管理的，服务需要将自己的IP地址和端口发送给注册中心，这样该服务才能被其他服务感知并调用。但是当服务在 docker 容器内运行时，服务获取到的自身IP是宿主机分配的内部IP（默认情况下会在 172.17.0.0/16 子网下），如 172.17.0.1 这个地址只能在宿主机内部使用（通过 docker0 网桥转发），其他的主机是无法 ping 通地。我们就以服务注册的场景讨论 docker 容器跨主机通信方案。

#### 端口映射

启动容器时通过 -p 参数将容器内服务监听的端口映射到主机端口中。例如容器运行的 web 服务监听 8080 端口，那么当指定 -p 8080:80 时，外部就可以通过访问宿主机的 80 端口访问到这个 web 服务了。

这种方式有一个很大的缺点：服务器端口是一种稀缺资源，一台主机往往会运行多个容器，它们之间很可能会出现端口冲突的情况，而且就服务注册这个场景而言，容器内的 web 服务是无法主动得到宿主机的ip地址的，因此需要我们在启动容器时通过 Dockerfile 将宿主机IP通过环境变量注入到容器中，然后配置 web 项目使用我们指定的 IP 来注册自身。这种方式显然无法应用于大规模集群部署。

#### 不进行网络隔离，直接使用宿主机网络配置

通过 –net=host 参数可以指定使用该模式。在这种模式下，容器的网络环境并没有通过 Linux 内核的 Network Namespace 进行隔离，在容器内可以自由修改宿主机的网络参数，因此是不安全的，但优点是网络性能损失可以忽略不计。对于我们的场景来说，微服务能够想直接部署一样征程获取到主机IP。

#### 组件 overlay 网络

Overlay 网络其实就是隧道技术，即将一种网络协议包装在另一种协议中传输的技术。Docker 常见的 overlay 网络实现有 flannel，swarm overlay，Open vSwitch 等。它们的工作流程基本都是一样的：通过某种方式保证所有 docker 容器都有全局唯一的 IP，然后把 docker 容器的ip和其他所在宿主机ip的对应关系存放到第三方存储服务中（如 etcd，consul），之后通过在宿主机上修改路由表、创建虚拟网卡的方式，将数据包转发到目标容器所在的宿主机上，最后再由目标宿主机的 docekr0 网桥转发给容器。对 flannel 来说，它的工作原理如下：

![../_images/flannel_work.png](C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\flannel_work.png)

10.56.78.1 和 10.56.78.2 是局域网内的两台物理机，它们各运行着container01和container02。当container01要访问container02时：

1. 数据包首先到达 docker0，由于 flannel 修改了路由表，docker0 会将其转发给 flannel0
2. flannel 的守护进程 flanneld 会持续监听flannel 转出的数据包，它首先会到 etcd 中查询 container01 所在的宿主机的 IP(10.56.78.1)，然后将原数据包进行封装（可以使用 UDP 或 vxlan 封装），把目的的IP地址改为对方宿主机IP并交由 eth0
3. etcd 将新数据包通过网络发到 10.56.78.2
4. 10.56.78.2 的 eth0 收到数据包后转发给 flannel0，由守护进程 flanneld 进行解包，取出原数据包，得到容器IP地址 172.17.0.2，然后转发给 docker0
5. docker0 将数据包转发至容器进程对应端口

至此 container01 就实现了跨主机访问 container02。

overlay 网络的性能损耗取决于其实现方式，经测试，flannel(vxlan模式)，swarm overlay 实现的损耗几乎与端口映射持平，但是 docker 1.12 版本新加入的 swarm overlay 实现性能损耗高达 60%（swarm overlay 代码实现质量不高）。因此，在生产环境中不建议使用 swarm overlay 方案。

#### Calico 和 Weave

这两种实现的方式跟 overlay 不太一样，它会把每台宿主机都当成一个路由器使用，数据包在各个主机之间流动最终被投递到目标主机。为了让主机支持路由功能，它们会向路由表中写入大量记录，因此如果集群中的节点太多，路由表记录数过高（超过1万）时性能会出现问题。

虽然实现原理一样，但它们的性能区别还是很大的，Calico 因为使用的是内核特性，能做到在内核态完成路由，因此性能于原生网络非常接近（90%以上），而 Weave 则是在用户态转发数据包，性能比较差，损耗高达 70% 以上。

#### 总结

overlay 方案和 Calico，Weave 由于可以实现容器IP的直接通信，因此在服务注册的场景下都可以正常运行，到那时需要付出一定的性能代价。而端口映射方式则需要强行配置我们的应用使用指定IP，灵活性极差，只适用于小规模的集群部署。而 host 模式则是通过牺牲隔离性来换取最大化网络性能。在实际应用中我们应该根据业务特点来选择最适合的网络方案。

## 网络基础使用

### 与 bridge 相关的参数

可以为 `docker container run` 命令使用

- `--hostname HOSTNAME` 选项为容器指定主机名，例如

  ```bash
  $ docker container --rm --net=bridge --hostname=bbox.clemente.com busybox:latest nslookup bbox.clemente.com
  ```

- `--dns DNS_SERVER_IP` 选项能够为容器指定所使用的 dns 服务器地址，例如

  ```bash
  $ docker container run --dns 8.8.8.8 busybox:latest nslookup docker.com
  ```

- `--add-host HOSTNAME:IP` 选项能够为容器指定本地主机名解析项，例如

  ```bash
  $ docker container run --rm --dns 8.8.8.8 -add-host "docker.com:172.16.0.100" busybox:latest nslookup docker.com
  ```

### 打开入站通讯

- `--publish`

  > 选项使用格式

 - `--publish <ContainerPort>`

   > 将制定的容器端口映射至主机所有地址的一个动态端口

 - `--publish <HostPort>:<ContainerPort>`

   > 将容器端口 <ContainerPort> 映射至指定的主机端口 <hostPort>

 - `--publish <ip>::<ContainerPort>`

   > 将指定的容器端口 <ContainerPort> 映射至主机指定 <ip> 的动态端口

 - `--publish <ip>:<hostPort>:<containerPort>`

   > 将指定的容器端口 <containerPort> 映射至主机指定 <ip> 的端口 <hostPort>

“动态端口” 指的是随机端口，具体的映射结果可以使用 docker port 命令查看

```bash
$ docker container port wordpresss_wordpress_1
80/tcp -> 0.0.0.0:80
```

- `--publish-all` 选项将容器的所有计划要暴露端口全部都映射至主机端口

- 计划要暴露的端口使用 `--expose` 选项指定

  ```bash
  docker container run --detach --publish-all --expose 3333 --expose 2222 --name=web01 busybox:latest /bin/httpd -p 2222 -f
  ```

  - >查看映射结果

    ```bash
    docker container port web01
    2222/tcp -> 0.0.0.0:32772
    3333/tcp -> 0.0.0.0:32771
    ```

- 如果不想使用默认的 docker0 桥接口，或者需要修改此桥接口的网络属性，可以通过 `docker daemon` 命令使用 `-b` `--bip` `--fixed-cidr` `--default-gateway` `--dns` `--mtu` 等选项进行设定。也可以通过修改 `/etc/docker/daemon.json` 配置文件设定。

- docker 守护进程的 C/S，默认仅监听 Unix Socket 格式的地址 `/var/run/docker.sock`

  > 如果使用 TCP 套接字，需要修改 `/etc/docker/daemon.json` 文件。 使用 `-H|--host` 选项可远程链接开启 TCP 套接字文件的 docker server。

## 存储卷

- Docker 镜像由多个只读层叠加而成，启动容器时，Docker 会加载只读镜像层并在镜像栈顶部添加一个读写层
- 如果运行中的容器修改了现有的一个已存在的文件，那该文件将会从读写层下面的只读层复制到读写层，该文件的只读版本仍然存在，只是已经被读写层中该文件的副本所隐藏，此即“写时复制（COW）”机制。

<img src="C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\Copy_on_write-164123276624419.png" alt="../_images/Copy_on_write.png" style="zoom:80%;" />

COW 这种机制我们增删改查等一类的操作必然会降低文件系统的效率，那带来的是那些对I/O要求较高的应用（例如：RedisMySQL）实现持久化存储的时候，这样的存储系统性能会大打折扣。

如果要绕过这种机制，我们可以通过存储卷来实现。特全级的名称空间当中，我们也可以理解为宿主机当中找一个本地文件系统，创建一个本地目录，把这个目录与容器内部的文件系统的某一目录创建绑定关系。

### 什么是卷

- 关闭并重启容器，其数据不受影响；但删除 Docker 容器，则其更改将会全部丢失

- 存在的问题

  > - 存储与联合文件系统中，不易被宿主机访问
  > - 容器间数据共享不便
  > - 删除容器其数据会丢失

- 解决方案 “卷”

  > “卷” 是容器上的一个或多个“目录”，此类目录可以绕过联合文件系统，与宿主机上的某目录“绑定（关联）”

### 有状态服务 VS 无状态服务

- 无状态服务（Stateless Service）

  > 是指该服务运行的实例不会在本地存储需要持久化的数据，并且多个实例对于同一个请求响应的结果是完全一致的。这类服务在 k8s 平台创建后，借助 k8s 内部的负载均衡，当访问该服务的请求到达服务一端后，负载均衡会随机找到一个实例来完整该请求的响应（目前为轮询）。这类服务的实例可能会应为一些原因停止或者重新创建（如扩容时），这时，这些停止的实例里的所有信息（除日志和监控数据外）都将丢失（重启容器就会丢失）。因此如果您的容器实例里需要保留重要的信息，并希望随时可以备份以便与以后可以恢复的话，那么建议您创建有状态服务。

- 有状态服务（Stateful Service）

  > 是指该服务的实例可以将一部分数据随时进行备份，并且在创建一个新的有状态服务时，可以通过备份恢复这些数据，以达到数据持久化的目的。有状态服务只能有一个实例，因此不支持“自动服务容量调节”。一般来说，数据库服务或者需要在本地文件系统存储配置文件或其他永久数据的应用程序可以创建使用有状态服务。想要创建有状态服务，必须满足几个前提：
  >
  > 待创建的服务镜像（image）的 Dockerfile 中必须定义了存储卷（Volume），因为只有存储所在目录里的数据可以被备份。 创建服务时，必须指定给该存储卷分配的磁盘空间大小。 如果创建服务的同时需要从之前的一个备份里恢复数据，那么还要指明该存储卷用哪个备份恢复。

- 无状态服务和有状态服务主要有以下几点区别

 1. 实例数量

    > 无状态服务可以有一个或多个实例，因此支持两种服务容量调节模式；有状态服务智能有一个实例，不允许创建多个实例，因此也不支持服务容量调节模式。

 2. 存储卷

    > 无状态服务可以有存储卷，也可以没有，即使有也无法备份存储卷里面的数据；有状态服务必须有存储卷，并且在创建服务时，必须指定给该存储卷分配的磁盘的空间大小。

 3. 数据存储

    > 无状态服务在运行过程中的所有数据（除日志和监控数据）都存在容器实例的文件系统中，如果实例停止或删除，则这些数据都将丢失，无法找回；而对于有状态服务，凡是已经挂载了存储卷的目录下的文件内容都可以随时进行备份，备份的数据可以下载，也可以用于恢复新的服务。但对于没有挂载卷的目录下的数据，仍然时无法备份和保存的，如果实例停止或者删除，这些非挂载卷里的文件内容同样会丢失。

### volume 的几种形态

有状态容器有数据持久化需求。Docker 采用 AFUS 分层文件系统时，文件系统的改动都是发生在最上面的容器层。在容器的声明周期内，他是持续的，包括容器在被停止后。但是，当容器被删除后，该数据层也随之被删除了。因此，Docker 采用 volume（卷）的形式来向容器提供持久化存储。Docker volume 有如下几种状态。

#### 无 —— 不使用 Docker volume

默认情况下，容器不使用任何 volume，此时，容器的数据被保存在容器之内，它只在容器的生命周期内存在，会随着容器的被删除而删除。当然，也可以使用 docker commit 命令将它持久化为一个新的镜像。

#### Data volume（数据卷）

一个 data volume 是容器中绕过 Union 文件系统的一个特定的目录。它被设计用来保存数据，而不管容器的生命周期。因此，当你删除一个容器时，Docker 肯定不会自动地删除一个 volume。有如下几种方式来使用 data volume：

- 使用 `-v local_file:container_file` 形式

  > ```
  > docker container run --detach --publish-all --name kvstor --volume ~/Documents/redis/redis.conf:/usr/local/etc/redis/redis.conf redis:4.0-alpine
  > ```
  >
  > ```
  > docker container inspect kvstor
  > ...
  > "Mounts": [
  >     {
  >         "Type": "bind",
  >         "Source": "/Users/clemente/Documents/docker-compose/redis/redis.conf",
  >         "Destination": "/usr/local/etc/redis/redis.conf",
  >         "Mode": "",
  >         "RW": true,
  >         "Propagation": "rprivate"
  >     },
  > ...
  > ```

- 使用 `-v container_dir` 形式 Docker-managed volume

  > ```
  > docker container run --detach --name web01 --volume /webapp nginx
  > ```
  >
  > ```
  > "Mounts": [
  >     {
  >         "Type": "volume",
  >         "Name": "fb00ff0ceb59cc1e1f1cb995ccddf071660146142f64b2a6e81037b37454c614",
  >         "Source": "/var/lib/docker/volumes/fb00ff0ceb59cc1e1f1cb995ccddf071660146142f64b2a6e81037b37454c614/_data",
  >         "Destination": "/webapp",
  >         "Driver": "local",
  >         "Mode": "",
  >         "RW": true,
  >         "Propagation": ""
  >     }
  > ],
  > ```
  >
  > 其实，在 web01 容器被删除后，/var/lib/docker/volumes/fb00ff0ceb59cc1e1f1cb995ccddf071660146142f64b2a6e81037b37454c614/_data 目录及其中的内容都还会保留下来，但是新启动的容器无法再使用这个目录，也就是说，已有的数据不能自动地被重复使用。

- 使用 `-v local_dir:container_dir` 形式 Bind mount volume

  > ```
  > docker container run --publish-all --detach --name web02 --volume /Users/clemente/Documents/HarborCloud-docs/build/html:/usr/share/nginx/html nginx
  > ```
  >
  > ```
  > docker container inspect web02
  > ...
  > "Mounts": [
  >     {
  >         "Type": "bind",
  >         "Source": "/Users/clemente/Documents/HarborCloud-docs/build/html",
  >         "Destination": "/usr/share/nginx/html",
  >         "Mode": "",
  >         "RW": true,
  >         "Propagation": "rprivate"
  >     }
  > ],
  > ...
  > ```
  >
  > 主机上的目录可以时一个本地目录，也可以在一个 NFS Share 内，或者在一个已经格式化好了的块设备上。

其实这种形式和第一种没有本质的区别，容器内对 /usr/share/nginx/html 的操作都会反应到主机的 ~/Documents/HarborCloud-docs/build/html 目录内。只是，重新启动容器时，可以再次使用同样的方式来将 ~/Documents/HarborCloud-docs/build/html 目录挂载到新的容器内，这样就可以实现数据持久化的目标。

#### 使用 data container

如果要在容器之间共享数据，最好是使用 data container。
这种 container 中不会跑应用，而只是挂载一个卷。比如：创建一个 data container

```
docker container create --volume /dbdata --name dbstore busybox
```

启动一个 app container

```
docker container run --detach --publish-all --name web03 --volumes-from dbstore nginx
```

其实，对 web03 这个容器来说，volume 的本质没有变，它只是将 dbstore 容器的 /dbdata 目录映射的主机上的目录映射到自身的 /dbdata 目录。

```json
"Mounts": [
 {
     "Type": "volume",
     "Name": "47373e7814371d703fe7a94b2282eecb3dbce122ae1faf001739231f054b8d42",
     "Source": "/var/lib/docker/volumes/47373e7814371d703fe7a94b2282eecb3dbce122ae1faf001739231f054b8d42/_data",
     "Destination": "/dbdata",
     "Driver": "local",
     "Mode": "",
     "RW": true,
     "Propagation": ""
 }
],
```

这样做的优势是不管其目录的临时性而不断地重复使用它。

#### 使用 docker volume 命令

Docker 新版本中引入了 docker volume 命令来管理 Docker volume

- 使用默认的 `local` driver 创建一个 volume

  > ```bash
  > $ docker volume create --name vol1
  > $ docker volume inspect volume1
  > [
  >     {
  >         "CreatedAt": "2018-10-30T05:05:54Z",
  >         "Driver": "local",
  >         "Labels": {},
  >         "Mountpoint": "/var/lib/docker/volumes/vol1/_data",
  >         "Name": "vol1",
  >         "Options": {},
  >         "Scope": "local"
  >     }
  > ]
  > ```

- 使用这个 volume

  > ```bash
  > $ docker container run --detach --publish-all --name web04 --volume vol1:/volume nginx
  > ```
  >
  > 结果还是相同，将 vol1 对应的主机上的目录挂载给容器内的 /volume 目录
  >
  > ```json
  > "Mounts": [
  >     {
  >         "Type": "volume",
  >         "Name": "vol1",
  >         "Source": "/var/lib/docker/volumes/vol1/_data",
  >         "Destination": "/volume",
  >         "Driver": "local",
  >         "Mode": "z",
  >         "RW": true,
  >         "Propagation": ""
  >     }
  > ],
  > ```

### volume 删除和孤独 volume 清理

1. 在删除容器的时候 volume

   > 可以使用 `docker container rm -v volume_name` 命令在删除容器的时候删除该容器的卷
   >
   > ```
   > docker container --volumes --force web04
   > ```
   >
   > ```
   > docker volume ls
   > DRIVER              VOLUME NAME
   > local               fb00ff0ceb59c..64b2a6e81037b37454c614
   > local               vol1
   > ```

2. 批量删除孤独的 volumes

   > 从上面的介绍可以看出，使用 `docker container run --volume` 启动的容器被删除以后，在主机上会遗留下来孤单的卷。可以使用下面的简单方法来做清理：
   >
   > ```bash
   > $ docker volume ls --quiet --filter dangling=true
   > 01e516feecef370..64b2a6e81037b37454c614
   > vol1
   > $ docker volume rm $(docker volume ls --quiet --filter dangling=true)
   > 01e516feecef3701b84e766a21dd2988c53978e223070fed2636eaba56109c5e
   > b08f68c5170e417ce4c4aab6667c1aadebb4a2cf6af39099d7b7e3dc36c6b74a
   > fb00ff0ceb59cc1e1f1cb995ccddf071660146142f64b2a6e81037b37454c614
   > vol1
   > $ docker volume ls
   > DRIVER              VOLUME NAME
   > local               47373e7814371d70..001739231f054b8d42
   > ```
   >
   > 也可以直接使用自带的清楚策略
   >
   > ```bash
   >$ docker volume prune
   > WARNING! This will remove all local volumes not used by at least one container.
   > Are you sure you want to continue? [y/N] y
   > Deleted Volumes:
   > vol1
   >
   > Total reclaimed space: 0B
   > ```

## Dockerfile

从上一小节的 volume 的介绍中，我们可以了解到，镜像的定制实际上就是定制每一层所添加的配置、文件。如果我们可以把每一层修改、安装、构建、操作的命令都写入一个脚本，用这个脚本来构建、定制镜像，那么之前提及的无法重复的问题、镜像构建透明性的问题、体积的问题就都会解决。这个脚本就是 Dockerfile。

Dockerfile 是一个文本文件，其内包含了一条条的指令（Instruction），每一条指令构建一层 ，因此每一条指令的内容，就是描述该层应当如何构建。

我们以定制 Nginx 镜像为例，我们使用 Dockerfile 来定制。在一个空白目录中，建立一个文本文件，并命名为 `Dockerfile` :

```bash
$ mkdir mynginx
$ cd mynginx
$ touch Dockerfile
FROM nginx
RUN echo '<h1>Hello, Docker!</h1>' > /usr/share/nginx/html/index.html
```

这个 Dockerfile 很简单，一共就两行。涉及到了两条指令，**FROM** 和 **RUN** 。

### FROM 指定基础镜像

所谓制定镜像，那一定是以一个镜像为基础，在其上进行定制。就像运行了一个 **nginx**，再进行修改一样，基础镜像是必须指定的。而 **RROM** 就是指定基础镜像，因此一个 **Dockerfile** 中 **FROM** 是必备的指令，并且必须是第一条指令。

在 [Docker Hub](https://hub.docker.com/)上有非常多的高质量的官方镜像，有可以直接拿来使用的服务类的镜像，如 [nginx](https://hub.docker.com/images/nginx)/[redis](https://hub.docker.com/images/redis)/[mongo](https://hub.docker.com/images/mongo)/[mysql](https://hub.docker.com/images/mysql)/[httpd](https://hub.docker.com/images/httpd)/[php](https://hub.docker.com/images/php) [tomcat](https://hub.docker.com/images/tomcat) 等；也有一些方便开发、构建、运行各种语言应用的镜像，如 [node](https://hub.docker.com/images/node)/[openjdk](https://hub.docker.com/images/openjdk)/[python](https://hub.docker.com/images/python)/[ruby](https://hub.docker.com/images/ruby)/[golang](https://hub.docker.com/images/golang) 等。可以在其中寻找一个最符合我们最终目标的镜像为基础镜像进行定制。

如果没有找到对应服务的镜像，官方镜像中还提供了一些更为基础的操作系统镜像，如 [ubuntu](https://hub.docker.com/images/ubuntu)/[debian](https://hub.docker.com/images/debian)/[centos](https://hub.docker.com/images/centos)/[fedora](https://hub.docker.com/images/fedora)/[alpine](https://hub.docker.com/images/alpine) 等，这些操作系统的软件库为我们提供了更广阔的扩展空间。

#### scratch 空白镜像

除了选择现有的镜像为基础镜像外，Docker 还存在一个特殊的镜像，名为 **scratch** 。这个镜像是虚拟的概念，并不实际存在，它表示一个空白的镜像。

```
FROM scratch
...
```

如果你以 **scratch** 为基础镜像的话，意味着你不以任何镜像为基础，接下来所写的指令将作为镜像的第一层开始存在。

不以任何系统为基础，直接将可执行文件复制进镜像的做法并不罕见，比如 **swarm** **coreos/etcd** 。对于 Linux 下静态编译的程序来说，并不需要有操作系统提供运行时支持，所需的一切库都已经在可执行文件里了，因此直接 `FROM scratch` 会让镜像体积更加小巧。使用 Go 语言 开发的应用很多会使用这种方式来制作镜像，这也是为什么有人认为 Go 是特别适合容器微服务架构的语言的原因之一。

### RUN 执行命令

**RUN** 指令是用来执行命令行命令的。由于命令行的强大能力，**RUN** 指令在定制镜像时是最常用的指令之一。其格式有两种：

- **shell** 格式：`RUN <command>` 就像直接在命令行中输入的命令一样。刚才写的 Dockerfile 中的 **RUN** 指令就是这种格式。

  ```dockerfile
  RUN echo '<h1>Hello, Docker!</h1>' > /usr/share/nginx/html/index.html
  ```

- **exec** 格式： `RUN ["executable file", "arg1", "arg2"]` 这更像是函数中调用的格式。

既然 **RUN** 就像 Shell 脚本一样可以执行命令，那么我们是否就可以像 Shell 脚本一样把每个命令对应一个 **RUN** ? 比如这样：

```dockerfile
FROM debian:jessie

RUN apt-get update
RUN apt-get install -y gcc lib6-dev make
RUN wget -O redis.tar.gz "http://download.redis.io/releases/redis-3.2.5.tar.gz"
RUN mkdir -p /usr/src/redis
RUN tar -zxf redis.tar.gz -C /usr/src/redis --strip-components=1
RUN make -C /usr/src/redis
RUN make -C /usr/src/redis install
```

之前说过，Dockerfile 中每一个指令都会建立一层，**RUN** 也不例外。每一个 **RUN** 的行为，就和刚才我们手工建立镜像的过程一样：新建立一层，在其上执行这些命令，执行结束后， `commit` 这一层的修改，构成新的镜像。

而上面的这种写法，创建了7层镜像。这是完全没有意义的，而且很多运行时不需要的东西，都被装进了镜像里，比如编译环境、更新的软件包等等。结果就是产生非常臃肿、非常多层的镜像，不仅仅增加构建部署的时间，也很容易出错。这是很多 Docker 初学者常犯的一个错误。

Union FS 是有**最大层数限制**的，比如 AUFS，之前是最大不得超过 42 层，现在是不得超过 127 层。 上面的 **Dockerfile** 正确的写法应该是这样的：

```dockerfile
FROM debian:jessie

RUN buildDeps='gcc libec6-dev make' \
    && apt-get update \
    && apt-get install -y $buildDeps \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-3.2.5.tar.gz" \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && rm -rf /var/lib/apt/lists/* \
    && rm redis.tar.gz \
    && rm -r /usr/src/redis \
    && apt-get purge -y --auto-remove $buildDeps
```

首先，之前所有的命令只有一个目的，就是编译、安装 redis 可执行文件。因此没有必要建立很多层，这只是一层的事情。因此，这里没有使用多个 `RUN` 一一对应不同的命令，而是仅仅使用一个 `RUN``指令，并使用 ``&&` 将各个所需命令串联起来。将之前的 7 层，简化为 1 层。在撰写 Dockerfile 的时候，要经常提醒自己，这并不是在写 shell 脚本，而是在定义每一层该如何构建。

并且，这里为了格式化还进行了换行。Dockerfile 支持 Shell 类的行尾添加 `\` 的换行符命令方式，以及行首 `#` 进行注释的格式。良好的格式，比如换行、缩进、注释等，会让维护、排障更为容易，这是一个比较好的习惯。

此外，还可以看到这一组命令的最后添加了清理工作的命令，删除了为了编译构建所需要的软件，清理了所有下载、展开的文件，并且还清理了 **apt** 缓存文件。这是很重要的一步，我们之前说过，镜像是多层存储，每一层的东西并不会在下一层被删除，会一直跟随着镜像。因此镜像构建时，一定要确保每一层只添加真正需要添加的东西，任何无关的东西都应该清理掉。

Docker 初学者制作的 Docker 镜像非常臃肿的原因之一，就是忘记了每一层构建的最后一定要清理掉无关文件。

### 构建镜像

好了，让我们再回到之前定制的 nginx 镜像的 Dockerfile 来。现在我们明白了这个 Dockerfile 的内容，那么让我们来构建这个镜像。

在 **Dockerfile** 文件所在目录执行：

```bash
$ docker image build -t nginx:v3 .
Sending build context to Docker daemon  2.048kB
Step 1/2 : FROM nginx:1.14-alpine
---> 14d4a58e0d2e
Step 2/2 : RUN echo '<h1>Hello, World!</h1>' > /usr/share/nginx/html/index.html
---> Running in 56c88dfe6001
Removing intermediate container 56c88dfe6001
---> 4987c2fc5455
Successfully built 4987c2fc5455
Successfully tagged nginx:v3
```

从命令的输出结果中，我们可以清晰的看到镜像的构建过程。在 **Step 2** 中，如同我们之前所说的那样，**RUN** 指令启动了一个容器 `14d4a58e0d2e` ，执行了所要求的命令，并最后提交了这一层 `56c88dfe6001` ，随后删除了所用到的这个容器 `14d4a58e0d2e` 。

这里我们使用了 `docker build` 命令进行镜像构建，其格式为：

```bash
docker [--host [socket|tcp]] image build [options] <Dockerfile_Context/URL/->
```

在这里我们指定了最终镜像的名称 `--tag nginx:v3` ，构建成功后，我们可以运行 `nginx:v3` 镜像。

### 镜像构建上下文（Context）

如果注意，会看到 `docker image build` 命令最后一个 `.` 。 `.` 表示当前目录，而 **Dockerfile** 就在当前目录，因此不少初学者以为这个路径时在指定 **Dockerfile** 所在路径，这样理解不准确。如果对应上面的命令格式，你会发现，这是在指定**上下文路径**。为什么时上下文？

首先我们要理解 `docker image build` 的工作原理。Docker 在运行时分为 Docker 引擎（也就是服务端守护进程）和客户端工具。Docker 的引擎提供了一组 REST API，被称为 Docker Remote API，而如 `docker` 命令这样的客户端工作，则是通过这组 API 与 Docker 引擎交互，从而完成各种功能。因此，虽然表面上我们好像时在本机执行各种 `docker` 功能，但实际上，一切都是使用的远程调用形式在服务端（Docker 引擎）完成。也因为这种 C/S 设计，让我们操作远程服务器的 Docker 引擎变得轻而易举。

当我们进行镜像构建的时候，并非所有定制都会通过 **RUN** 指令完成，经常会需要将一些本地文件复制进镜像，比如通过 **COPY** 指令、**ADD** 指令等。而 `docker image build` 命令构建镜像，其实并非在本地构建，而是在服务端，也就是说 Docker 引擎中构建的。那么在这种客户端/服务端的架构中，如何才能让服务端获得本地文件呢？

这就引入了上下文的概念。当构建的时候，用户会指定构建镜像上下文的路径，`docker image build` 命令得知这个路径后，**会将路径下的所有内容打包**，然后上传给 Docker 引擎。这样 Docker 引擎收到这个上下文包后，展开就会获得构建镜像所需的一切文件。

如果在 **Dockerfile** 中这么写：

```
COPY ./package.json /app/
```

这并不是要复制执行 `docker image build` 命令所在的目录下的 package.json，也不是复制 **Dockerfile** 所在目录下的 package.json，而是复制 **上下文（context）** 目录下的 package.json 。

因此，**COPY** 这类指令中的源文件的路径都是相对路径。这也是初学者经常会问为什么 `COPY ../package.json /app` 或者 `COPY /opt/xxxx /app` 无法工作的原因，因为这些路径已经超出了上下文的范围，Docker 引擎无法获得这些位置的文件。如果真的需要那些文件，应该将它们复制到上下文目录中去。

现在就可以理解刚才的命令 `docker image build --tag nginx:v3 .` 中这个 `.` ，实际上是在指定上下文的目录，`docker image build` 命令会将该目录心爱的内容打包交给 Docker 引擎以帮助构建镜像。

如果观察 `docker image build` 输出，我们其实已经看到了这个发送上下文的过程：

```bash
$ docker image build -t nginx:v3 .
Sending build context to Docker daemon  2.048kB
```

#### .dockerignore 忽略指定上下文

理解构建上下文对镜像构建是很重要的，避免犯一些不应该的错误。比如有些初学者在发现 `COPY /opt/xxxx /app` 不工作后，于是干脆将 **Dockerfile** 放到了硬盘根目录去构建，结果发现 `docker image build` 执行后，在发送一个几十GB的东西，极为缓慢而且很容易构建失败。那是因为这种做法是在让 `docker image build` 打包整个硬盘，这显然是使用错误。

一般来说，应该将 **Dockerfile** 置于一个空目录下，或者项目根目录下。如果该目录下没有所需文件，那么应该把所需文件复制一份过来。如果目录下有些东西确实不希望构建时传给 Docker 引擎，那么可以用 `.gitignore` 一样的语法写一个 `.dockerignore` ，该文件是用于剔除不需要作为上下文传递给 Docker 引擎的。

那么为什么会有人误以为 `.` 是指定 **Dockerfile** 所在目录呢？这是因为在默认情况下，如果并不要求必须位于上下文目录中，比如可以用 `-f ../Dockerfile.php` 参数指定某个文件作为 **Dockerfile**。

当然，一般大家习惯性的会使用默认的文件名 **Dockerfile**，以及会将其置于镜像构建上下文目录中。

### 其他构建镜像方法

- 直接用 Git repo 进行构建

  或许你已经注意到了， `docker image build` 还支持从 URL 构建，比如可以直接从 Git repo 中构建：

  ```bash
  $ docker image build https://github.com/jenkinsci/jenkins.git\#jenkins-2.149
  Sending build context to Docker daemon   60.3MB
  Step 1/17 : FROM maven:3.5.4-jdk-8 as builder
  ---> 985f3637ded4
  Step 2/17 : COPY .mvn/ /jenkins/src/.mvn/
  ---> Using cache
  ---> 449d4e56d53e
  Step 3/17 : COPY cli/ /jenkins/src/cli/
  ---> Using cache
  ---> 841e76c4f7d8
  Step 4/17 : COPY core/ /jenkins/src/core/
  ---> Using cache
  ---> b6b7d47e8294
  Step 5/17 : COPY src/ /jenkins/src/src/
  ---> Using cache
  ---> e7a46ef570cf
  Step 6/17 : COPY test/ /jenkins/src/test/
  ---> Using cache
  ---> e1d52ec3c4ad
  Step 7/17 : COPY war/ /jenkins/src/war/
  ---> Using cache
  ---> 3e24961339fc
  Step 8/17 : COPY *.xml /jenkins/src/
  ...
  ```

  这行命令指定了构建所需的 Git repo，并且指定默认的 **master** 分支，构建目录为 `/jenkins-2.149/` ，然后 Docker 就会自己去 `git clone` 这个项目、切换到指定分支、并进入到指定目录后开始构建。

- 用给定的 tar 压缩包构建

  ```bash
  $ docker image build http://server/context.tar.gz
  ```

  如果给出的 URL 不是 Git repo，而是个 tar 压缩包，那么 docker 引擎会下载这个压缩包，并自动解压缩，以其作为上下文，开始构建。

- 从标准输入中读取 Dockerfile 进行构建

  ```bash
  $ docker image build - < Dockerfile
  // 或者
  $ cat Dockerfile | docker image build -
  ```

  如果标准输入传入的是文本文件，则将其视为 **Dockerfile** ，并开始构建。这种形式由于直接从标准输入中读取 Dockerfile 内容，它没有上下文，因此不可以像其他方法那样将本地文件 **COPY** 进镜像之类的事情。

- 从标准输入中读取上下文压缩包进行构建

  ```bash
  $ docker image build - < context.tar.gz
  ```

  如果发现标准输入的文件格式是 **gzip** **bzip2** 以及 **xz** 的话，将会使其为上下文压缩包，直接将其展开，将里面视为上下文，并开始构建。

## 多阶段构建

### 之前的做法

在 **Docker 17.05** 版本之前，我们构建 Docker 镜像时，通产会采用两种方式：

- 全部放入一个 Dockerfile

  一种方式是将所有的构建过程包含在一个 **Dockerfile** 中，包括项目及其依赖库的编译、测试、打包等流程，这里可能会带来一些问题：

  - **Dockerfile** 特别长，可维护性降低
  - 镜像层次多，镜像体积大较大，部署时间长
  - 源代码存在泄漏的风险

  例如，编写 `app.go` 文件，该程序输出 `Hello World!`

  ```go
  package main

  import "fmt"

  func main() {
      fmt.Printf("Hello World!");
  }
  ```

  编写 `Dockerfile.one` 文件

  ```dockerfile
  FROM golang:1.9-alpine

  RUN apk --no-cache add git ca-certificates

  WORKDIR /go/src/github.com/go/hellworld/

  COPY app.go .

  RUN go get -d -v github.com/go-sql-driver/mysql \
      && CGO_ENABLED=0 GOOS=linux go build -a installsuffix cgo -o app . \
      && cp /go/src/github.com/go/helloworld/app /root

  WORKDIR /root/

  CMD ["./app"]
  ```

  构建镜像

  ```bash
  $ docker image build --tag go/helloworld:1 --file Dockerfile.one .
  ```

- 分散到多个 Dockerfile

  另一种方式，就是我们事先在一个 **Dockerfile** 将项目及其依赖库编译测试打包好后，再将其拷贝到运行环境中，这种方式需要我们编写两个 **Dockerfile** 和一些编译脚本才能将其两个阶段自动整合起来，这种方式虽然可以很好地规避第一种方式存在的风险，但明显部署过程较复杂。

  例如

  编写 `Dockerfile.build` 文件

  ```dockerfile
  FROM golang:1.9-alpine

  RUN apk --no-cache add git

  WORKDIR /go/src/github.com/go/helloworld

  COPY app.go .

  RUN go get -d -v github.com/go-sql-driver/mysql \
   && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
  ```

  编写 `Dockerfile.copy` 文件

  ```dockerfile
  FROM alpine:latest

  RUN apk --no-cache add ca-certificates

  WORKDIR /root/

  COPY app .

  CMD ["./app"]
  ```

  新建 `build.sh`

  ```shell
  #!/bin/sh
  echo Building go/helloworld:build

  docker image build --tag go/helloworld:build . --file Dockerfile.build

  docker container create --name extract go/helloworld:build
  docker container cp extract:/go/src/github.com/go/helloworld/app ./app
  docker container rm --force extract

  echo Building go/helloworld:2

  docker image build --no-cache --tag go/helloworld:2 . --file Dockerfile.copy
  rm ./app
  ```

  现在运行脚本即可构建镜像

  ```bash
  $ chmod +x build.sh
  $ ./build.sh
  ```

  对别两种方式生成的镜像大小

  ```bash
  $ docker image ls
  REPOSITORY      TAG IMAGE           ID  CREATED     SIZE
  go/helloworld   2   f7cf3465432c    22  seconds ago 6.47MB
  go/helloworld   1   f55d3e16affc    2   minutes ago 295MB
  ```

### 使用多阶段构建

为解以上的问题，**Docker v17.05** 开始支持多阶段构建（`multistage builds`）。使用多阶段构建我们就可以很容易解决前面提到的问题，并且只需要编写一个 **Dockerfile** ：

例如

编写 **Dockerfile** 文件

```dockerfile
FROM golang:1.9-alpine as builder

RUN apk --no-cache add git

WORKDIR /go/src/github.com/go/helloworld/

RUN go get -d -v github.com/go-sql-driver/mysql

COPY app.go .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest as prod

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=0 /go/src/github.com/go/helloworld/app .

CMD ["./app"]
```

构建镜像

```bash
$ docker image build --tag go/helloworld:3 .
```

对比三个镜像的大小

```bash
$ docker image ls
REPOSITORY      TAG IMAGE           ID              CREATED SIZE
go/helloworld   3   d6911ed9c846    7 seconds ago   6.47 MB
go/helloworld   2   f7cf3465432c    22 seconds ago  6.47 MB
go/helloworld   1   f55d3e16affc    2 minutes ago   295 MB
```

很明显使用多阶段构建的镜像体积小，同时也完美解决了上边提到的问题。

### 只构建某一阶段的镜像

我们可以使用 `as` 来为某一阶段命令，例如：

```bash
FROM golang:1.9-alpine as builder
```

例如当我们只构建 `builder` 阶段的镜像时，我们可以使用 `docker image build` 命令时加上 `--target` 参数即可

```bash
$ docker image build --target builder --tag username/imagename:tag
```

### 构建时聪其他镜像复制文件

上面例子中我们使用 `COPY --from=0 /go/src/github.com/go/helloworld/app .` 从上一阶段的镜像中复制文件，我们也可以复制任何镜像中的文件。

```dockerfile
COPY --from=nginx:latest /etc/nginx/nginx.conf /nginx.conf
```

## Docker Registry

### Registry 分类

- Registry 用于保存 docker 镜像，包括镜像的层次结构和元数据。

- 用户可自建 Registry，也可以使用官方的 Docker Hub

- 详细分类

 - Sponsor Registry

   > 第三方的 Registry，供客户和 Docker 社区使用

 - Mirror Registry

   > 第三方的 Registry，只让客户使用

 - Vendor Registry

   > 由发布 Docker 镜像的供应商提供的 Registry

 - Private Registry

   > 通过设有防火墙和额外的安全层的私有实体提供的 Registry

### 私有仓库操作

有时候使用 Docker Hub 这样的公共仓库可能不方便，用户可以创建一个本地仓库供私人仓库。

创建好私有仓库之后，就可以使用 `docker tag` 来标记一个镜像，然后推送它到仓库。例如私有仓库地址为 ``127.0.0.1:5000` 。

先在本机查看已有的镜像。

```bash
$ docker image ls
REPOSITORY     TAG      IMAGE ID            CREATED             VIRTUAL SIZE
ubuntu         latest   ba5877dc9bec        6 weeks ago         192.7 MB
```

使用 `docker image tag` 将 `ubuntu:latest` 这个镜像标记为 `127.0.0.1:5000/ubuntu:latest` 。
格式为 `docker image IMAGE[:TAG] [REGISTRY_HOST[:REGISTRY_PORT]/]REPOSITORY[:TAG]` 。

```bash
$ docker tag ubuntu:latest 127.0.0.1:5000/ubuntu:latest
$ docker image ls
REPOSITORY                        TAG       IMAGE ID            CREATED             VIRTUAL SIZE
ubuntu                            latest    ba5877dc9bec        6 weeks ago         192.7 MB
127.0.0.1:5000/ubuntu:latest      latest    ba5877dc9bec        6 weeks ago         192.7 MB
```

使用 `docker image push` 上传标记的镜像

```bash
$ docker push 127.0.0.1:5000/ubuntu:latest
The push refers to repository [127.0.0.1:5000/ubuntu]
373a30c24545: Pushed
a9148f5200b0: Pushed
cdd3de0940ab: Pushed
fc56279bbb33: Pushed
b38367233d37: Pushed
2aebd096e0e2: Pushed
latest: digest: sha256:fe4277621f10b5026266932ddf760f5a756d2facd505a94d2da12f4f52f71f5a size: 1568
```

用 `curl` 查看仓库中的镜像。

```bash
$ curl 127.0.0.1:5000/v2/_catalog
{"repositories":["ubuntu"]}
```

这里可以看到 `{"repositories":"[ubuntu]"}` ，这表明镜像已经被成功上传。

先删除已有镜像，在尝试从私有仓库中下载这个镜像。

```bash
$ docker image rm 127.0.0.1:5000/ubuntu:latest

$ docker image pull 127.0.0.1:5000/ubuntu:latest
Pulling repository 127.0.0.1:5000/ubuntu:latest
ba5877dc9bec: Download complete
511136ea3c5a: Download complete
9bad880da3d2: Download complete
25f11f5fb0cb: Download complete
ebc34468f71d: Download complete
2318d26665ef: Download complete

$ docker image ls
REPOSITORY                         TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
127.0.0.1:5000/ubuntu:latest       latest              ba5877dc9bec        6 weeks ago         192.7 MB
```

### 注意事项

如果你不想使用 `127.0.0.1:5000` 作为仓库地址，比如想让本网段的其他主机也能把镜像推送到私有仓库。你就得把例如 `192.168.199.100:5000` 这样的内网地址作为私有仓库地址，这时你会发现无法成功推送镜像。

这是因为 Docker 默认 不允许非 HTTPS 方式推送镜像。我们可以通过 Docker 的配置选项来取消这个限制。

对于使用 `systemd` 的系统，请在 `/etc/docker/daemon.json` 中写入如下内容（如果文件不存在请新建该文件）

```json
{
    "registry-mirror": [
        "https://registry.docker-cn.com"
    ],
    "insecure-registries": [
        "192.168.199.100:5000"
    ]
}
```

Note

该文件必须符合 json 规范，否则 Docker 将不能启动。

## 资源限制

在使用 docker 运行容器时，一台主机上可能会运行几百个容器，这些容器虽然互相隔离，但是底层却使用着相同的 CPU、内存和磁盘资源。如果不对容器使用的资源进行限制，那么容器之间会相互影响，小的来说会导致容器资源使用不公平；大的来说，可能会导致主机和集群资源耗尽，服务完全不可用。

docker 作为容器的管理者，自然提供了控制容器资源的功能。正如使用内核的 namespace 来做容器之间的隔离，docker 也是通过内核的 cgroup 来做容器的资源限制。这篇文章就介绍如何使用 docker 来限制 CPU、内存和IO，以及对应的 cgroups 文件。

我们本地测试的 docker 版本是 `18.06.1-ce`，操作系统是 `CentOS 7.4.1708`

Note

不同版本和系统的功能会有差异，具体的使用方法和功能请以具体版本的 docker 官方文档为准。

#### stress 测试容器压力

我们使用 [stress](https://github.com/progrium/docker-stress) 容器来产生 CPU、内存和 IO 的压力，具体的使用请参考它的帮助文档。

### CPU 资源

主机上的进程会通过时间分片机制使用 CPU，CPU 的量化单位是频率，也就是每秒钟能执行的运算次数。为容器限制 CPU 资源并不能改变 CPU 的运行频率，而是改变每个容器能使用的 CPU 时间片。理想状态下，CPU 应该一直处于运行状态（并且进程需要的计算量不会超过 CPU 的处理能力）。

- docker 限制 CPU Share

  > docker 允许用户为每个容器设置一个数字，代表容器的 CPU Share，默认情况下每个容器的 share 是 1024。要注意，这个shere是相对的，本身并不能代表任何确定的意义。当主机上有多个容器运行时，每个容器占用的 CPU 时间比例为它的 share 在总额中的比例。举个例子，如果主机上有两个一直使用 CPU 的容器（为了简化理解，不考虑主机上其他进程），如果主机上有两个一直使用 CPU 的容器（为了简化理解，不考虑主机上其他进程），其 CPU Share 都是 1024，那么两个容器 CPU 使用率都是 50%；如果把其中一个容器的 share 设置为 512，那么两者 CPU 的使用率分别为 67% 和 33%；如果删除 share 为 1024 的容器，剩下来容器的 CPU 使用率将会是 100%。
  >
  > 总结下来，这种情况下，docker 会根据主机上运行的容器和进程动态调整每个容器使用 CPU 的时间比例。这样的好处是能保证 CPU 尽可能处于运行状态，充分利用 CPU 资源，而且保证所有容器的相对公平；缺点是无法指定容器使用 CPU 的确定值。
  >
  > docker 为容器设置 CPU share 的参数是 `-c --cpu-shares` ，它的值是一个整数。
  >
  > 我的主机是 2 核心的 CPU，因此使用 `stress` 启动 4 个进程来产生计算压力：
  >
  > ```bash
  > $ docker container run --rm --interactive --tty progrium/stress --cpu 2
  > stress: info: [1] dispatching hogs: 2 cpu, 0 io, 0 vm, 0 hdd
  > stress: dbug: [1] using backoff sleep of 6000us
  > stress: dbug: [1] --> hogcpu worker 2 [6] forked
  > stress: dbug: [1] using backoff sleep of 3000us
  > stress: dbug: [1] --> hogcpu worker 1 [7] forked
  > ```
  >
  > 在另外一个 terminal 使用 `htop` 查看资源的使用情况：
  >
  > ![../_images/htop_01.png](C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\htop_01.png)
  >
  > 从上图中可以看到，CPU 2个核心资源都达到了 100%。如果两个 stress 进程 CPU 使用率没有达到 100% 是因为系统中还有其他容器在运行。
  >
  > 为了比较，另外启动一个 share 为 512 的容器：
  >
  > ```bash
  > $ docker container run --rm --interactive --tty --cpu-shares 1024 --detach progrium/stress --cpu 2
  > 56b5a33cbd21c3d02af582034e7bf8edf66f97a2c9daec8390d101ab60e8842e
  > $ docker container run --rm --interactive --tty --cpu-shares 512 --detach progrium/stress --cpu 2
  > 499e280058fc8280583c8833aaf9b07b0ca4e0e74a87f2dafd12bd970cca0625
  > ```
  >
  > 因为默认情况，容器的 CPU share 为 1024，所以这两个容器的 CPU 使用率应该大致为 2:1，下面时启动第二个容器之后的监控截图：
  >
  > ![../_images/htop_02.png](C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\htop_02.png)
  >
  > 两个容器分别启动了两个 `stress` 进程，第一个容器 `stress` 进程 CPU 使用率都在 66% 左右，第二个容器 `stress` 进程 CPU 使用率在 33% 左右，比例关系大致为 2:1，符合之前的预期。

- 限制容器能使用的 CPU 核心数

  > 上面讲述的 `-c --cpu-shares` 参数只能限制容器使用 CPU 的比例，或者说优先级，无法确定地限制容器使用 CPU 的具体核心数；从 1.13 版本之后，docker 提供了 `--cpus` 参数可以限定容器能使用的 CPU 核心数。这个功能可以让我们更精确的设置容器 CPU 使用量，是一种更容易理解也因此更常用的手段。
  >
  > `--cpus` 后面跟着一个浮点数，代表容器最多使用的核心数，可以精确到小数点两位，也就是说容器最小可以使用 `0.01` 核心的 CPU。比如，我们可以限制容器智能使用 `1.0` 核心数的 CPU：
  >
  > ```
  > # docker container run --rm --interactive --tty --cpus 1.0 progrium/stress --cpu 2
  > stress: info: [1] dispatching hogs: 2 cpu, 0 io, 0 vm, 0 hdd
  > stress: dbug: [1] using backoff sleep of 6000us
  > stress: dbug: [1] --> hogcpu worker 2 [6] forked
  > stress: dbug: [1] using backoff sleep of 3000us
  > stress: dbug: [1] --> hogcpu worker 1 [7] forked
  > ```
  >
  > 在容器里启动两个 stress 来跑 CPU 压力，如果不加限制，这个容器会导致 CPU 的使用率为 %200 左右（也就是说会占用两个核心的计算能力）。实际的监控如下图：
  >
  > ![../_images/htop_03.png](C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\htop_03.png)
  >
  > 可以看到，每个 `stress` 进程 CPU 使用率大约在 50%，总共的使用率为 100%，符合一颗核心的设置。
  >
  > 如果设置的 `--cpus` 值大于主机的 CPU 核心数，docker 会直接报错：
  >
  > ```bash
  > $ docker container run --rm --interactive --tty --cpus 4 progrium/stress --cpu 2
  > docker: Error response from daemon: Range of CPUs is from 0.01 to 2.00, as there are only 2 CPUs available.
  > See 'docker run --help'.
  > ```
  >
  > 如果多个容器都设置了 `--cpus` ，并且它们之和超过主机的CPU核心数，并不会导致容器失败或者退出，这些容器之间回竞争使用CPU，具体配置分配的 CPU 数量取决于主机运行情况和容器的 CPU Share 值。也就是说 `--cpus` 只能保证在 CPU 资源充足的情况下容器最多能使用的 CPU 数，docker 并不能保证在任何情况下容器都能使用这么多的 CPU（因为这根本是不可能的）。

- 限制容器运行在某些 CPU 核心

  > 现在的笔记本和服务器都会有多个 CPU，docker 也允许调度的时候限定容器运行在哪个 CPU 上。比如，我的主机上有2个核心，可以通过 `--cpuset-cpus` 参数让容器只运行在前两个核心上：
  >
  > ![../_images/htop_04.png](C:\Users\admin\Documents\devops\Linux-Basics\docker\._images\docker_use\htop_04.png)
  >
  > `--cpuset-cpus` 参数可以和 `-c --cpu-shares` 一起使用，限制容器只能运行在某些 CPU 核心上，并且配置了使用率。
  >
  > 限制容器运行在哪些核心上并不是一个很好的做法，因为它需要事先知道主机上有多少 CPU 核心，而且非常不灵活。除非有特别的需求，一般并不推荐在生产中这样使用。

- CPU 信息的 cgroup 文件

  > 所有和容器 CPU share 有关的配置都保存在 `/sys/fs/cgroup/cpu/docker/<docker_id>/` 目录下面，其中 `cpu.shares` 保存了 CPU share 的值（其他文件的意义可以查看 cgroups 的官方文档）：
  >
  > ```bash
  > $ ls /sys/fs/cgroup/cpu/docker/94e9747a84da1dbe0783b183a65d56308fa97534e102a6ba7aa4bf8193680a5e/
  > cgroup.clone_children  cgroup.procs  cpuacct.usage         cpu.cfs_period_us  cpu.rt_period_us   cpu.shares  notify_on_release
  > cgroup.event_control   cpuacct.stat  cpuacct.usage_percpu  cpu.cfs_quota_us   cpu.rt_runtime_us  cpu.stat    tasks
  > ```
  >
  > 和 cpuset（限制 CPU 核心）有关的文件在 `/sys/fs/cgroup/cpuset/docker/<docker_id>` 目录下，其中 `cpuset.cpus` 保存了当前容器能使用的 CPU 核心。
  >
  > ```bash
  > $ ls /sys/fs/cgroup/cpuset/docker/94e9747a84da1dbe0783b183a65d56308fa97534e102a6ba7aa4bf8193680a5e/
  > cgroup.clone_children  cpuset.cpu_exclusive  cpuset.mem_hardwall     cpuset.memory_spread_page  cpuset.sched_load_balance        tasks
  > cgroup.event_control   cpuset.cpus           cpuset.memory_migrate   cpuset.memory_spread_slab  cpuset.sched_relax_domain_level
  > cgroup.procs           cpuset.mem_exclusive  cpuset.memory_pressure  cpuset.mems                notify_on_release
  > $ cat /sys/fs/cgroup/cpuset/docker/94e9747a84da1dbe0783b183a65d56308fa97534e102a6ba7aa4bf8193680a5e/cpuset.cpus
  > 0-1
  > ```
  >
  > `--cpus` 限制 CPU 核心数并不像上面两个参数一样有对应的文件，它是由 `cpu.cfs_period_us` 和 `cpu.cfs_quota_us` 两个文件控制的。如果容器的 `--cpus` 设置为 3，其对应的这两个文件值为：
  >
  > ```bash
  > ~ cat /sys/fs/cgroup/cpu/docker/233a38cc641f2e4a1bec3434d88744517a2214aff9d8297e908fa13b9aa12e02/cpu.cfs_period_us
  > 100000
  > ~ cat /sys/fs/cgroup/cpu/docker/233a38cc641f2e4a1bec3434d88744517a2214aff9d8297e908fa13b9aa12e02/cpu.cfs_quota_us
  > 300000
  > ```
  >
  > 其实在 1.12 以及之前的版本，都是通过 `--cpu-period` 和 `--cpu-quota` 这两个参数控制容器能使用的 CPU 核心数的。前者表示 CPU 的周期数，默认是 100000，单位是微秒，也就是 1s，一般不需要修改；后者表示容器在上述的 CPU 周期里能使用的 quota，真正能使用的 CPU 核心数就是 `cpu-quota/cpu-period` ，因此对于 3 核心的容器，对应的 `cpu-quota` 值为 `300000` 。

### 内存资源

**默认情况下，docker 并没有对容器内存进行限制**，也就是说容器可以使用主机提供的所有内存。者当然是非常危险的事情，如果某个容器运行了恶意的内存消耗软件，或者代码由内存泄漏，很可能回导致主机内存耗尽，因此导致服务不可用。对于这种情况，docker 会设置 docker daemon 的 OOM (out of memory) 值，使其在内存不足的时候被杀死的优先级降低。另外，就是你可以为每个容器设置内存使用的上限，一旦超过这个上限，容器会被杀死，而不是耗尽主机的内存。

限制内存上限虽然能保护主机，到那时也可能会伤害到容器里的服务。如果为服务设置的内存上限太小，会导致服务还在正常工作的时候就被 OOM 杀死；如果设置的过大，会因为调度器算法浪费内存。因此，合理的做法包括：

- 为应用做内存压力测试，理解正常业务需求下使用的内存情况，然后才能进入生产环境使用
- 一定要限制容器的内存使用上限
- 尽量保证主机的资源充足，一旦通过监控发现资源不足，就进行扩容或者对容器进行迁移
- 如果可以（内存资源充足的情况），尽量不要使用 swap，swap 的使用会导致内存计算复杂，对调度器非常不友好

- docker 限制容器的内存使用量

  > 在 docker 启动参数中，和内存限制有关的包括（参数的值一般是内存大小，也就是一个正数，后面跟着内存单位 **b**:guilabel:k:guilabel:m:guilabel:g，分别对应 bytes、KB、MB、GB）：
  >
  > > - `-m --memory` : 容器能使用的最大内存大小，最小值为 4m
  > > - `--memory-swap` : 容器能够使用的 swap 大小
  > > - `--memory-swappiness` : 默认情况下，主机可以把容器使用的匿名页（anonymous page）swap 出来，你可以设置一个 0-100 之间的值，代表允许 swap 出来的比例
  > > - `--memory-reservation` : 设置一个内存使用的 soft limit，如果 docker 发现主机内存不足，会执行 OOM 操作。这个值必须小于 `--memory` 设置的值
  > > - `--kernel-memory` : 容器能够使用 kernel memory 大小，最小值为 4m。
  > > - `--oom-kill-disable` : 是否运行 OOM 的时候杀死容器。只有设置了 `-m` 才可以把这个选项设置为 false，否则容器会耗尽主机内存，而且导致主机应用被杀死。
  >
  > 关于 `--memory-swap` 的设置必须解释一下， `--memory-swap` 必须在 `--memory` 也配置的情况下才能有用。
  >
  > > - 如果 `--memory-swap` 的值大于 `--memory` ，那么容器能使用的总内存（内存+swap）为 `--memory-swap` 的值，能使用的 swap 值为 `--memory-swap` 减去 `--memory` 的值。
  > > - 如果 `--memory-swap` 为 0，或者和 `--memory` 的值相同，那么容器能使用两倍于内存的 swap 大小，如果 `--memory` 对应的值是 `200M` ，那么容器可以使用 `400m` swap。
  > > - 如果 `--memory-swap` 的值为 -1，那么不限制 swap 的使用，也就是说主机有多少 swap，容器都可以使用。
  >
  > 如果限制容器的内存使用为 64M，在申请 64M 资源的情况下，容器运行正常（如果主机上内存非常紧张，并不一定能保证这一点），因为单位换算率的差异，容器里的进程被 KILL 掉了：
  >
  > ```
  > $ docker --host tcp://cicd.clemente.com:2376 container run --rm --interactive --tty --memory 64m progrium/stress:latest --vm 1 --vm-bytes 64M --vm-hang 0
  > stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
  > stress: dbug: [1] using backoff sleep of 3000us
  > stress: dbug: [1] --> hogvm worker 1 [6] forked
  > stress: dbug: [6] allocating 67108864 bytes ...
  > stress: dbug: [6] touching bytes in strides of 4096 bytes ...
  > stress: FAIL: [1] (416) <-- worker 6 got signal 9
  > stress: WARN: [1] (418) now reaping child worker processes
  > stress: FAIL: [1] (422) kill error: No such process
  > stress: FAIL: [1] (452) failed run completed in 0s
  > ```
  >
  > 如果申请 100M 内存，会发现容器里的进程被 KILL 掉了（worker 6 got signal 9，signal 9 就是 kill 信号）
  >
  > ```
  > $ docker --host tcp://cicd.clemente.com:2376 container run --rm --interactive --tty --memory 64m progrium/stress:latest --vm 1 --vm-bytes 100M --vm-hang 0
  > stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
  > stress: dbug: [1] using backoff sleep of 3000us
  > stress: dbug: [1] --> hogvm worker 1 [6] forked
  > stress: dbug: [6] allocating 104857600 bytes ...
  > stress: dbug: [6] touching bytes in strides of 4096 bytes ...
  > stress: FAIL: [1] (416) <-- worker 6 got signal 9
  > stress: WARN: [1] (418) now reaping child worker processes
  > stress: FAIL: [1] (422) kill error: No such process
  > stress: FAIL: [1] (452) failed run completed in 0s
  > ```
  >
  > 关于 swap 和 kernel memory 的限制就不在这里过多解释了，感兴趣的可以查看官方的文档。

- 内存信息的 cgroups 文件

  > 对于 docker 来说，它的内存限制也是存放在 cgroups 文件系统的。对于某个容器，你可以在 `/sys/fs/cgroups/memory/docker/<container_id>` 目录下看到容器内存相关的文件：
  >
  > ```bash
  > $ ls /sys/fs/cgroup/memory/docker/94e9747a84da1dbe0783b183a65d56308fa97534e102a6ba7aa4bf8193680a5e/
  > cgroup.clone_children           memory.kmem.tcp.max_usage_in_bytes  memory.oom_control
  > cgroup.event_control            memory.kmem.tcp.usage_in_bytes      memory.pressure_level
  > cgroup.procs                    memory.kmem.usage_in_bytes          memory.soft_limit_in_bytes
  > memory.failcnt                  memory.limit_in_bytes               memory.stat
  > memory.force_empty              memory.max_usage_in_bytes           memory.swappiness
  > memory.kmem.failcnt             memory.memsw.failcnt                memory.usage_in_bytes
  > memory.kmem.limit_in_bytes      memory.memsw.limit_in_bytes         memory.use_hierarchy
  > memory.kmem.max_usage_in_bytes  memory.memsw.max_usage_in_bytes     notify_on_release
  > memory.kmem.slabinfo            memory.memsw.usage_in_bytes         tasks
  > memory.kmem.tcp.failcnt         memory.move_charge_at_immigrate
  > memory.kmem.tcp.limit_in_bytes  memory.numa_stat
  > ```
  >
  > 而上面的内存限制对应的文件是 `memory.limit_in_bytes` ：
  >
  > ```bash
  > $ cat /sys/fs/cgroup/memory/docker/94e9747a84da1dbe0783b183a65d56308fa97534e102a6ba7aa4bf8193680a5e/memory.limit_in_bytes
  > 9223372036854771712
  > ```

### IO 资源（磁盘）

对于磁盘来说，考量的参数是容量和读写速度，因此对容器的磁盘限制也应该从这两个维度出发。目前 docker 支持对磁盘的读写速度进行限制，但是并没有方法能限制容器能使用的磁盘容量（一旦磁盘 mount 到容器里，容器就能够使用磁盘的所有容量）。

```bash
$ docker container run --interactive --tty --rm ubuntu:16.04 bash
root@faeb980ed4d5:/$ time $(dd if=/dev/zero of=/tmp/test.data bs=10M count=100 && sync)
100+0 records in
100+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 1.62132 s, 647 MB/s

real        0m3.000s
user        0m0.000s
sys 0m1.580s
root@faeb980ed4d5:/#
```

- 限制磁盘的权重

  > 通过 `--blkio-weight` 参数可以设置 block 的权重，这个权重和 `--cpu-shares` 类似，它是一个相对值，取值范围是 10-1000，当多个 block 去写磁盘的时候，其读写速度和权重成反比。
  >
  > 不过在我的环境中， `--blkio-weight` 参数虽然设置了对应的 cgroups 值，但是并没有作用，不同的 weight 容器的读写速度还是一样的。github 上有一个对应的 [issue](https://github.com/moby/moby/issues/16173) ，但是没有详细的解答。
  >
  > `--blkio-weight-device` 可以设置某个设备的权重值，测试下来虽然两个容器同时读的速度不同，但是并没有按照对应的比例来限制。

- 限制磁盘的读写速率

  > 除了权重之外，docker 还允许你直接限制磁盘的读写速率，对应的参数有：
  >
  > - `--device-read-bps` 磁盘每秒最多就可以读多少比特 (bytes)
  > - `--device-write-bps` 磁盘美妙最多可以写多少比特 (bytes)
  >
  > 上面两个参数的值都是磁盘以及对应的速率，格式为 `<device-path>:<limit>[unit]` ， `device-path` 标示磁盘所在的位置，限制 `limit` 为正整数，单位可以是 `kb` 、 `mb` 和 `gb` 。
  >
  > 比如可以把设备的读速率限制在 1mb
  >
  > ```bash
  > $ docker run -it --device /dev/sda:/dev/sda --device-read-bps /dev/sda:1mb ubuntu:16.04 bash
  > root@6c048edef769:/$ cat /sys/fs/cgroup/blkio/blkio.throttle.read_bps_device
  > 8:0 1048576
  > root@6c048edef769:/$ dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=5M count=10
  > 10+0 records in
  > 10+0 records out
  > 52428800 bytes (52 MB) copied, 50.0154 s, 1.0 MB/s
  > ```
  >
  > 从磁盘中读取 50m 花费了 50s 左右，说明磁盘速率限制起了作用。
  >
  > 另外两个参数可以限制磁盘读写频率（每秒能执行多少读写操作）：
  >
  > - `--device-read-iops` 磁盘每秒最多可以执行多少 IO 读操作
  > - `--device-write-iops` 磁盘每秒最多可以执行多少 IO 写操作
  >
  > 上面两个参数的值都是磁盘以及对应的 IO 上限，格式为 `<device-path>:<limit>` ，limit 为正整数，表示磁盘 IO 上限数量。
  >
  > 比如，我们可以让磁盘每秒最多读 100 次 ：
  >
  > ```bash
  > $ docker run -it --device /dev/sda:/dev/sda --device-read-iops /dev/sda:100 ubuntu:16.04 bash
  > root@2e3026e9ccd2:/$ dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=1k count=1000
  > 1000+0 records in
  > 1000+0 records out
  > 1024000 bytes (1.0 MB) copied, 9.9159 s, 103 kB/s
  > ```
  >
  > 从测试中可以看出，容器设置了读操作的 iops 为 100，在容器内部从 block 中读取 1m 数据（每次 1k,一共要读 1000次），共计耗时约 10s，换算起来就是 100 iops/s，符合预期结果。
  >
  > 写操作 bps 和 iops 读类似，这里就不再重复了，感兴趣可以自己实验。

- 磁盘信息的 cgroups 文件

  > 容器中磁盘限制的 cgroups 文件为于 `/sys/fs/cgroup/blkio/docker/<docker_id>` 目录：
  >
  > ```bash
  >  $ ls /sys/fs/cgroup/blkio/docker/1402c1682cba743b4d80f638da3d4272b2ebdb6dc6c2111acfe9c7f7aeb72917/
  > blkio.io_merged                   blkio.io_serviced                blkio.leaf_weight                blkio.throttle.io_serviced        blkio.time_recursive   tasks
  > blkio.io_merged_recursive         blkio.io_serviced_recursive      blkio.leaf_weight_device         blkio.throttle.read_bps_device    blkio.weight
  > blkio.io_queued                   blkio.io_service_time            blkio.reset_stats                blkio.throttle.read_iops_device   blkio.weight_device
  > blkio.io_queued_recursive         blkio.io_service_time_recursive  blkio.sectors                    blkio.throttle.write_bps_device   cgroup.clone_children
  > blkio.io_service_bytes            blkio.io_wait_time               blkio.sectors_recursive          blkio.throttle.write_iops_device  cgroup.procs
  > blkio.io_service_bytes_recursive  blkio.io_wait_time_recursive     blkio.throttle.io_service_bytes  blkio.time                        notify_on_release
  > ```
  >
  > 其中 `blkio.throttle.read_iops_device` 对应了设备的读 IOPS，前面一列是设备的编号，可以通过 `cat /proc/partitions` 查看设备和分区的设备号；后面是 IOPS 上限值：
  >
  > ```bash
  > $ cat /sys/fs/cgroup/blkio/docker/1402c1682cba743b4d80f638da3d4272b2ebdb6dc6c2111acfe9c7f7aeb72917/blkio.throttle.read_iops_device
  > 8:0 100
  > ```
  >
  > `blkio.throttle.read_bps_device` 对应了设备的读速率，格式和 IOPS 类似，只是第二列的值为 bps ：
  >
  > ```bash
  > $ cat /sys/fs/cgroup/blkio/docker/9de94493f1ab4437d9c2c42fab818f12c7e82dddc576f356c555a2db7bc61e21/blkio.throttle.read_bps_device
  > 8:0 1048576
  > ```

### 总结

从上面的实验可以看出来，CPU 和内存的资源限制已经是比较成熟和易用，能够满足大部分用户的需求。磁盘限制也是不错的，虽然现在无法动态地限制容量，但是限制磁盘读写速度也能应对很多场景。

至于网络，docker 现在并没有给出网络限制的方案，也不会在可见的未来做这件事情，因为目前网络是通过插件来实现的，和容器本身的功能相对独立，不是很容易实现，扩展性也很差。docker 社区已经有很多呼声，也有 issue 是关于网络流量限制的: [issue 26767](https://github.com/moby/moby/issues/26767)、[issue 37](https://github.com/moby/moby/issues/37)、[issue 4763](https://github.com/moby/moby/issues/4763)。

资源限制一方面可以让我们为容器（应用）设置合理的 CPU、内存等资源，方便管理；另外一方面也能有效地预防恶意的攻击和异常，对容器来说是非常重要的功能。如果你需要在生产环境使用容器，请务必要花时间去做这件事情。
