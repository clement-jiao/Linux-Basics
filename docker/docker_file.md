# Dockerfile 指令

我们已经介绍了 **FROM**、**RUN**，还提及了 **COPY**、**ADD**，其实 **Dockerfile** 功能很强大，它提供了十多个指令。下面我们继续学习其他的指令。

## COPY 复制文件

格式：

- `COPY <source_path>... <destination_path>`
- `COPY ["<source_path_01>",... "<destination_path>"]`

和 **RUN** 指令一样，也有两种格式，一种类似于命令行，一种类似于函数调用。

**COPY** 指令将从构建上下文目录中 `<source_path>` 的文件/目录复制到新的一层的镜像内 `<destination_path>` 位置。比如：

```
COPY package.json /usr/src/app
```

`<destination_path>` 可以是容器内的绝对路径，也可以是相对于工作目录的相对路径（工作目录可以用 **WORKDIR** 指令来指定）。目标路径不需要事先创建，如果目录不存在会在复制文件前先进行创建缺失目录。

此外，还需要注意一点，使用 **COPY** 指令，源文件的各种元数据都会保留。比如读、写、执行权限、文件变更时间等。这个特性对于镜像定制很有用。特别是构建相关文件都在使用 Git 进行管理的时候。

## ADD 更高级的复制文件

**ADD** 指令和 **COPY** 的格式和性质基本一致。但是在 **COPY** 基础上增加了一些功能。

比如 `<source_path>` 可以是一个 URL，这种情况下，Docker 引擎会试图去下载这个链接的文件放到 `<destination_path>` 去。下载后的文件权限自动设置为 **600**，如果这并不是想要的权限，那么还需要增加额外的一层 **RUN** 指令进行权限调整，另外，如果下载的是个压缩包，需要解压缩，也一样还需要额外的一层 **RUN** 指令进行解压缩。所以不如直接使用 **RUN** 指令，然后使用 wget 或者 curl 工具下载，处理权限、解压缩、然后清理无用文件更合理。因此，这个功能其实并不实用，而且不推荐使用。

如果 `<source_path>` 为一个 tar 压缩文件的话，压缩格式为 `gzip` `bzip2` 以及 `xz` 的情况下，**ADD** 指令将会自动解压缩这个压缩文件到 `<destination_path>` 去。

在某些情况下，这个自动解压缩的功能非常有用，比如官方镜像 [ubuntu Dockerfile](https://github.com/tianon/docker-brew-ubuntu-core/blob/c7e9f7353aa24d1c35f501e06382aed1b540e85f/bionic/Dockerfile) 中：

```
FROM scratch
ADD ubuntu-bionic-core-cloudimg-amd64-root.tar.gz /
...
```

但在某些情况下，如果我们真的希望复制这个压缩文件进去，而不解压缩，这时就不可以使用 **ADD** 命令了。

在 Docker 官方的 Dockerfile 最佳实践文档 中要求，尽可能的使用 **COPY**，因为 **COPY** 的语义很明确，就是复制文件而已，而 **ADD** 则包含了更复杂的功能，其行为也不一定很清晰。最适合使用 **ADD** 的场合，就是所提及的需要自动解压缩的场合。

另外需要注意的是，**ADD** 指令会令镜像构建缓存失效，从而可能会令镜像构建变得比较缓慢。

因此在 **COPY** 和 **ADD** 指令中选择的时候，可以遵循这样的原则，所有的文件复制均使用 **COPY** 指令，仅在需要自动解压缩的场合使用 **ADD**。

## CMD 容器启动命令

**CMD** 指令的格式和 **RUN** 相似，也是两种格式：

- **shell** 格式： `CMD <command>`
- **exec** 格式： `CMD ["executable", "arg1", "arg2"...]`
- 参数列表格式： `CMD ["arg1", "arg2"...]` 在指定了 **ENTRYPOINT** 指令后，用 **CMD** 指定具体的参数。

之前介绍容器的时候曾经说过，Docker 不是虚拟机，容器就是进程。既然是进程，那么在启动容器的时候，需要指定所运行的程序及参数。**CMD** 指令就是用于指定默认的容器主进程的启动命令的。

在运行时可以指定新的命令来替代镜像设置重的这个默认命令，比如，[ubuntu](https://store.docker.com/images/ubuntu) 镜像默认的 **CMD** 是 `/bin/bash` ，如果我们直接 `docker container run --tty --interactive ubuntu` 的话，会直接进入 bash。我们也可以在运行时指定运行别的命令，如 `docker container run --tty --interactive ubuntu cat /etc/os-release` 。这就是用 `cat /etc/os-release` 命令替换了默认的 `/bin/bash` 命令了，输出了系统版本信息。

在指令格式上，一般推荐使用 **exec** 格式，这类格式在解析时会被解析为 JSON 数组，因此一定要使用 `"` ，而不要使用单引号。

如果使用 **shell** 格式的话，实际的命令会被包装为 `sh -c` 的参数的形式进行执行。比如：

```dockerfile
CMD echo $HOME
```

在实际执行中，会将其变更为：

```dockerfile
CMD [ "sh", "-c", "echo $HOME" ]
```

这就是为什么我们可以使用环境变量的原因，因为这些环境变量会被 shell 进行解析处理。

提到 **CMD** 就不得不提容器中应用在前台执行和后台执行的问题。初学者常常会混淆。

Docker 不是虚拟机，容器中的应用都应该在前台执行，而不是像虚拟机、物理机里面那样，用 upstart/systemd 去启动后台服务，容器内没有后台服务的概念。

一些初学者将 **CMD** 写为：

```dockerfile
CMD service nginx start
```

然后发现容器执行后就立即退出了。甚至在容器内去使用 systemctl 命令结果却发现根本执行不了。这就是因为没有搞明白前台、后台的概念，没有区分容器和虚拟机的差异，依旧在以传统虚拟机的角度去理解容器。

对于容器而言，其启动程序就是容器应用进程，容器就是为了主进程而存在的，主进程退出，容器就失去了存在的意义，从而退出，其他辅助进程不是它需要关心的东西。

而使用 `service nginx start` 命令，则是希望 upstart 以后台守护进程的形式启动 nginx 服务。而刚才说了 `CMD service nginx start` 会被理解为 `CMD [ "sh", "-c", "service nginx start" ]` ，因此主进程实际上是 `sh` 。那么当 `service ngin start` 命令结束后， `sh` 也就结束了， `sh` 作为住进称退出了，自然就会令容器退出。

正确的做法是直接执行 nginx 可执行文件，并且要求以前台形式运行。

```bash
CMD [ "nginx", "-g", "daemon off;" ]
```

## ENTRYPOINT 入口点

**ENTRYPOINT** 的格式和 **RUN** 指令格式一样，分别为 **exec** 格式和 **shell** 格式。

**ENTRYPOINT** 的目的和 **CMD** 一样，都是在指定容器启动程序及参数。**ENTRYPOINT** 在运行时也可以替代，不过比 **CMD** 要略显繁琐，需要通过 `docker container run` 的参数 `--entrypoint` 来指定。

当指定了 **ENTRYPOINT** 后，**CMD** 的含义就发生了改变，不再是直接的运行其命令，而是将 **CMD** 的内容作为参数传给 **ENTRYPOINT** 指令，换句话说实际执行时，将变为：

```
<ENTRYPOINT> "<CMD>"
```

那么有了 **CMD** 后，为什么还要有 **ENTRYPOINT** 呢？这种 `<ENTRTYPOINT> <CMD>` 有什么好处？让我们来看几个场景。

- 场景一：让镜像变成像命令一样使用

  假设我们需要一个得知自己当前公网IP的镜像，那么可以先用 **CMD** 来实现：
  
  ```dockerfile
  FROM ubuntu:16.04
  RUN apt-get update \
   && apt-get install -y curl \
   && rm -rf /var/lib/apt/lists/*
  CMD ["curl", "-s", "http://ip.cn"]
  ```
  
  假如我们使用 `docker image build --tag=myip .` 来构建镜像的话，如果我们需要查询当前公网IP，只需要执行：
  
  ```bash
  $ docker container run --rm --name myip_test myip:1.0
  当前 IP: 58.246.147.26 来自: 上海市 联通
  ```
  
  嗯，这么看起来我们好像直接把镜像当作命令使用了，不过命令总有参数，如果我们希望加参数呢？比如从上面的 **CMD** 中可以看到实质的命令时 curl，那么如果我们希望显示 HTTP 头信息，就需要加上 `-i` 参数。那么我们可以直接加入 `-i` 参数给 `docker container run myip` 吗？
  
  ```bash
  $ docker container run --rm --name myip_test myip:1.0 -i
  docker: Error response from daemon: OCI runtime create failed: container_linux.go:348: starting container process caused "exec: \"-i\": executable file not found in $PATH": unknown.
  ```
  
  我们可以看到可执行文件找不到的报错，`executable file not found` 。之前我们说过，跟在镜像名后面的是 command，运行时会替换 **CMD** 的默认值。因此这里的 `-i` 替换了原来的 **CMD** ，而不是添加在原来的 `curl -s http://ip.cn` 后面。而 `-i` 根本不是命令，所以自然找不到。
  
  那么如果我们希望加入 `-i` 这参数，我们就必须重新完整的输入这个命令：
  
  ```bash
  $ docker container run --rm --name myip_test myip:1.0 curl -s http://ip.cn -i
  HTTP/1.1 200 OK
  Date: Thu, 01 Nov 2018 02:59:52 GMT
  Content-Type: text/html; charset=UTF-8
  Transfer-Encoding: chunked
  Connection: keep-alive
  Set-Cookie: __cfduid=d8b77ba972fb91bec979f9a212ceca6841541041192; expires=Fri, 01-Nov-19 02:59:52 GMT; path=/; domain=.ip.cn; HttpOnly
  Server: cloudflare
  CF-RAY: 472b1b9af36b9619-SJC
  
  当前 IP: 58.246.147.26 来自: 上海市 联通
  ```
  
  这显然不是很好的解决方案，而使用 **ENTRYPOINT** 就可以解决这个问题。现在我们重新用 **ENTRYPOINT** 来实现这个镜像：
  
  ```dockerfile
  FROM ubuntu:16.04
  
  RUN apt-get update \
   && apt-get install -y curl \
   && rm -rf /var/lib/apt/lists/*
  
  ENTRYPOINT [ "curl", "-s", "http://ip.cn" ]
  ```
  
  这次我们再来尝试直接使用 `docker container run myip -i` 。
  
  ```bash
  $ docker container run --rm --name myip_test myip:1.1
  当前 IP: 58.246.147.26 来自: 上海市 联通
  
  $ docker container run --rm --name myip_test myip:1.1 -i
  HTTP/1.1 200 OK
  Date: Thu, 01 Nov 2018 03:17:16 GMT
  Content-Type: text/html; charset=UTF-8
  Transfer-Encoding: chunked
  Connection: keep-alive
  Set-Cookie: __cfduid=d89a29d9467d6f00d7856b8a8f22d10791541042236; expires=Fri, 01-Nov-19 03:17:16 GMT; path=/; domain=.ip.cn; HttpOnly
  Server: cloudflare
  CF-RAY: 472b351850169668-SJC
  
  当前 IP: 58.246.147.26 来自: 上海市 联通
  ```
  
  可以看到，这次成功了。这是因为当存在 **ENTRYPOINT** 后，**CMD** 的内容将会作为参数传给 **ENTRYPOINT**，而这里 `-i` 就是新的 **CMD**，因为会作为参数传给 curl，从而达到了我们预期的效果。

- 场景二：应用运行前的准备工作

  启动容器就是启动主进程，但有些时候，启动主进程前，需要一些准备工作。
  
  比如 mysql 类的数据库，可能需要一些数据库配置、初始化的工作，这些工作要在最终的 mysql 服务器运行之前解决。
  
  此外，可能希望避免使用 **root** 用户去启动服务，从而提高安全性，而在启动服务前还需要以 root 身份执行一些必要的准备工作，最后切换到服务用户身份启动服务。或者除了服务之外，其他命令依旧可以使用 root 身份执行，方便调试等。
  
  这些准备工作是和容器 **CMD** 无关的，无论 **CMD** 是什么，都需要事先进行一个预处理工作。这种情况下，可以写一个脚本，然后放入 **ENTRYPOINT** 中执行，而这个脚本会将接收到的参数（也就是 **<CMD>**）作为命令，在脚本最后执行。比如官方镜像 [redis Dockerfile](https://github.com/docker-library/redis/blob/dc6dc737baa434528ce31948b22b4c6ccc78793a/5.0/Dockerfile) 中就是这么做的：
  
  ```dockerfile
  FROM alpine:3.4
  ...
  RUN addgroup -S redis && adduser -S -G redis redis
  ...
  ENTRYPOINT ["docker-entrypoint.sh"]
  
  EXPOSE 6379
  CMD [ "redis-server" ]
  ```
  
  可以看到其中为了 redis 服务创建了 redis 用户，并在最后指定了 **ENTRYPOINT** 为 `docker-entrypoint.sh` 脚本。
  
  ```shell
  #!/bin/sh
  set -e
  
  # first arg is `-f` or `--some-option`
  # or first arg is `something.conf`
  if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
   set -- redis-server "$@"
  fi
  
  # allow the container to be started with `--user`
  if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
   find . \! -user redis -exec chown redis '{}' +
   exec gosu redis "$0" "$@"
  fi
  
  exec "$@"
  ```
  
  该脚本的内容就是根据 **CMD** 的内容来判断，如果是 `redis-server` 的话，则切换到 `redis` 用户身份启动服务，否则依旧使用 root 身份执行。比如：
  
  ```bash
  $ docker container run --detach --publish-all --name kvstore redis:4.0-alpine
  1656bd2427fcc96e3e9dbdaf0e498786ca8817b5bb97e200476c555a117964c5
  
  $ docker container exec kvstore id
  uid=0(root) gid=0(root)
  ```

## ENV 设置环境变量

格式有两种：

- `ENV <key> <value>`
- `ENV <key1>=<value1> <key2>=<value2>...`

这个指令很简单，就是设置环境变量而已，无论是后面的其他指令，如 **RUN**，还是运行时的应用，都可以直接使用这里定义的环境变量。

```dockerfile
ENV VERSION=1.0 DEBUG=on \
    NAME="Happy Feet"
```

这个例子中演示了如何换行，以及对含有空格的值用双引号扩起来的办法，这和 Shell 下的行为是一致的。

定义了环境变量，那么在后续的指令中，就可以使用这个环境变量。比如在官方 node 镜像 Dockerfile 中，就有类似这样的代码：

```dockerfile
ENV NODE_VERSION 7.2.0

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep "node -v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs
```

在这里先定义了环境变量 `NODE_VERSION` ，其后的 **RUN** 这层里，多次使用 `$NODE_VERSION` 来进行操作定制。可以看到，将来升级镜像构建版本的时候，只需要更新 **7.2.0** 即可，**Dockerfile** 构建维护变得更轻松了。

下列指令可以支持环境变量的展开：

1.ADD
2.COPY
3.ENV
4.EXPOSE
5.LABEL
6.USER
7.WORKDIR
8.VOLUME
9.STOPSIGNAL
10.ONBUILD

可以从这个指令列表感觉到，环境变量可以使用的地方很多，很强大。通过环境变量，我们可以让一份 **Dockerfile** 制作更多的镜像，只需使用不同的环境变量即可。

## ARG 构建参数

格式： `ARG <parameter>[=<defaults>]`

构建参数和 **ENV** 的效果一样，都是设置环境变量。所不同的是，**ARG** 所设置的构建环境的环境变量，在将来容器运行时是不会存在这些环境变量的。但是不要因此就使用 **ARG** 保存密码之类的信息，因为 `docker image history IMAGE:TAG` 还是可以看到所有值的。

**Dockerfile** 中的 **ARG** 指令是定义参数名称，以及定义其默认值。该默认值可以在构建命令 `docker image build` 中用 `--build-arg <parameter>=<value>` 来覆盖。

在 **1.13** 之前的版本，要求 `--build-arg``中的参数名，必须在 :guilabel:`Dockerfile` 中用 :guilabel:`ARG` 定义过了，换句话说，就是 ``--build-arg` 指定的参数，必须在 **Dockerfile** 中使用了。如果对应参数没有被使用，则会报错退出构建。从 **1.13** 开始，这种严格的限制被放开，不再报错退出，而是显示警告信息，并继续构建。这对于使用 CI 系统，用同样的构建流程构建不同的 **Dockerfile** 的时候比较有帮助，避免构建命令必须根据每个 Dockerfile 的内容修改。

## VOLUME 定义匿名卷

格式为：

- `VOLUME ["<path1>", "path2"...]`
- `VOLUME <path>`

之前我们说过，容器运行时应该尽量保持容器存储层不发生写操作，对于数据库类需要保存动态数据的应用，其数据库文件应该保存于卷（volume）中。为了防止运行时用户忘记将动态文件所保存目录挂载为卷，在 **Dockerfile** 中，我们可以事先指定某些目录挂载为匿名卷，这样在运行时如果用户不指定挂载，其应用也可以正常运行，不会向容器存储层写入大量数据。

```
VOLUME /data
```

这里的 `/data` 目录就会在运行时自动挂载为匿名卷，任何向 `/data` 中写入的信息都不会记录进容器存储层，从而保证了容器存储层的无状态化。当然，运行时可以覆盖这个挂载设置。比如：

```
docker container --detach --volume mydata:/data xxxx
```

在这行命令中，就使用了 `mydata` 这个命名卷挂载到了 `/data` 这个位置，替代了 **Dockerfile** 中定义的匿名卷的挂载配置。

## EXPOSE 声明端口

格式为 `EXPOSE <port_1> [<port_2>...]`

**EXPOSE** 指令是声明运行时容器提供服务端口，这只是一个声明，在运行时并不会因为这个声明应用就会开启这个端口的服务。在 **Dockerfile** 中写入这样的声明有两个好处，一个是帮助镜像使用者理解这个镜像服务的守护端口，以方便配置映射；另一个用户则是在运行时使用随机端口映射时，也就是 `docker container run --publish-all` 时，会自动随机映射 **EXPOSE** 的端口。

此外，在早期 Docker 版本中还有一个特殊的用处。以前所有的容器都运行于默认桥接网络中，因此所有容器相互之间都可以之间访问，这样存在一定的安全性问题。于是有了一个 Docker 引擎参数 `--icc=false` ，当指定该参数后，容器间将默认无法互相访问，除非互相之间使用了 `--links` 参数的容器才可以互通，并且只有镜像中 **EXPOSE** 所声明的端口才可以被访问。这个 `--icc=false` 的用法，在引入了 `docker network` 后已经基本不用了，通过自定义网络可以很轻松的实现容器间的互联于隔离。

要将 **EXPOSE** 和在运行时使用 `--publish port_list` 区分开来。`--publish` 是映射宿主机端口和容器端口，换句话说，就是将容器的对应端口服务公开给外界访问，而 **EXPOSE** 仅仅是声明容器打算使用什么端口而已，并不会自动在宿主机进行端口映射。

## WORKDIR 指定工作目录

格式为 `WORKDIR <work directory path>`

使用 **WORKDIR** 指令可以来指定工作目录（或者称为当前目录），以后各层的当前目录就被改为指定的目录，如该目录不存在，**WORKDIR** 会帮你建立目录。

之前提到一些初学者常犯的错误是把 `Dockerfile` 等同于 Shell 脚本来书写，这种错误的理解还能会导致出现下面这样的错误：

```dockerfile
RUN cd /app
RUN echo "hello" > world.txt
```

如果将这个 “Dockerfile” 进行构建镜像运行后，会发现找不到 `/app/world.txt` 文件，或者其内容不是 hello。其原因很简单，在 Shell 中，连续两行是同一个进程执行环境，因此前一个命令修改的内存状态，会直接影响后一个命令；而在 **Dockerfile** 中，这两行 **RUN** 命令在执行环境根本不同，式两个完全不同的容器。这就是对 **Dockerfile** 构建分层存储的概念不了解所导致的。

之前说过每一个 **RUN** 都是启动一个容器、执行命令、然后提交存储层文件变更。第一层 `RUN cd /app` 的执行仅仅是当前进程的工作目录变更，一个内存上的变化而已，其结果不会造成任何文件变更。而到第二层的时候，启动的是一个全新的容器，跟第一层的容器更完全没有关系，自然不可能继承前一层构建过程中的内存变化。

因此如果需要改变以后各层的工作目录的位置，那么应该使用 `WORKDIR` 指令。

## USER 指定当前用户

格式： `USER <username>`

**USER** 指令和 **WORKDIR** 相似，都是改变环境状态并影响以后的层。**WORKDIR** 是改变工作目录，**USER** 则是改变之后层的执行 **RUN** 指令，**CMD** 以及 **ENTRYPOINT** 这类命令的身份。

当然，和 **WORKDIR** 一样，**USER** 只是帮助你切换指定用户而已，这个用户必须是事先建立好的，否则无法切换。

```dockerfile
RUN groupadd -r redis && useradd -r -g redis redis
USER redis
RUN [ "redis-server" ]
```

如果以 root 执行的脚本，在执行期间希望改变身份，比如希望以某个已经建立好的用户来运行某个服务进程，不要使用 su 或者 sudo ，这些都需要比较麻烦的配置，而且在 TTY 缺失的环境下经常出错。建议使用 gosu。

```dockerfile
# 建立 redis 用户，并使用 gosu 换另一个用户执行命令
RUN groupadd -r redis && useradd -r -g redis redis
# 下载 gosu
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
# 设置 CMD，并以另外的用户执行
CMD [ "exec", "gosu", "redis", "redis-server" ]
```

## HEALTHCHECK 健康检查

格式：

- `HEALTHCHECK [option] CMD <COMMAND>` 设置检查容器监控状态的命令
- `HEALTHCHECK NONE` 如果基础镜像有健康检查指令，使用这行可以屏蔽掉其健康检查指令

**HEALTHCHECK** 指令是告诉 Docker 应该如何进行判断容器的状态是否正常，这是从 **Docker 1.12** 引入的新指令。

在没有 **HEALTHCHECK** 指令前，Docker 引擎只可以通过容器内主进程是否退出来判断容器是否状态异常。很多情况下没有问题，但是如果程序进入了死锁状态，或者死循环状态，应用进程并不退出，但是该容器已经无法提供服务了。在 **1.12** 以前，Docker 不会检测到容器的这种状态，从而不会重新调度，导致可能会有部分容器已经无法提供服务了却还在接受用户请求。

而自 **1.12** 之后，Docker 提供了 **HEALTHCHECK** 指令后，用其启动容器，初始状态会为 **starting**，在 **HEALTHCHECK** 指令检查成功后变为 **healthy** ，如果连续一定次数失败，则会变为 **unhealthy**。

**HEALTHCHECK** 支持下列选项：

- `--interval=<second>` 两次健康检查的间隔，默认为 30 秒；
- `--timeout=<second>` 健康检查命令运行超时时间，如果超过这个时间，本次健康检查就被视为失败，默认 30 秒；
- `--retries=<number>` 当连续失败指定次数后，则将容器状态视为 **unhealthy**，默认 3 次。

和 **CMD** **ENTRYPOINT** 一样，**HEALTHCHECK** 只可以出现一次，如果写了多个，只有最后一个生效。

在 `HEALTHCHECK [option] CMD` 后面的命令，格式和 **ENTRYPOINT** 一样，分为 **shell** 格式，和 **exec** 格式。命令的返回值决定了该次健康检查的成功与否

| code | status  |
| ---- | ------- |
| 0    | success |
| 1    | fail    |
| 2    | save    |



| <font color='red'>Attention</font>             |
| ---------------------------------------------- |
| <font color='red'>**不要使用 2 这个值**</font> |

假设我们有个镜像是个最简单的 Web 服务，我们希望增加健康检查来判断其 Web 服务是否在正常工作，我们可以用 curl 来帮助判断，其 **Dockerfile** 的 **HEALTHCHECK** 可以这么写：

```dockerfile
FROM nginx:1.14.0

RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=5s --timeout=3s \
        CMD curl -fs http://localhost/ || exit 1
```

这里我们设置了每5秒检查一次（这里为了试验所以间隔非常短，实际应该相对较长），如果健康检查命令超过3秒没有响应就视为失败，并且使用 `curl -fs http://localhost/ || exit 1` 作为健康检查命令。

使用 `docker image build` 来构建这个镜像：

```
docker image build --tag=myweb:1.0 .
```

构建完成之后，我们启动一个容器：

```
container run --detach --publish 80:80 --name myweb_test myweb:1.0
```

当运行该镜像后，可以通过 `docker container ls` 看到最初的状态为 `(health: starting)` ：

```bash
$ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                   PORTS                     NAMES
6d9d2d0557de        myweb:1.0           "nginx -g 'daemon of…"   10 seconds ago      Up 9 seconds (healthy)   0.0.0.0:80->80/tcp        myweb_test
```

在等待几秒钟后，再次 `docker container ls` 就会看到健康状态变化为了 `(healthy)` ：

```bash
$ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                    PORTS                     NAMES
6d9d2d0557de        myweb:1.0           "nginx -g 'daemon of…"   22 seconds ago      Up 21 seconds (healthy)   0.0.0.0:80->80/tcp        myweb_test
```

如果健康检查连续失败超过了重试次数，状态就会变为 `(unhealthy)` 。

为了帮助排障，健康检查命令的输出（包括 stdout 以及 stderr） 都会被存储在健康状态里，可以用 `docker container inspect CONTAINER` 来查看。

```bash
$ docker container inspect --format '{{json .State.Health}}' myweb_test | python -m json.tool
{
    "Status": "healthy",
    "FailingStreak": 0,
    "Log": [
        {
            "Start": "2018-11-01T09:13:48.06308Z",
            "End": "2018-11-01T09:13:48.1525581Z",
            "ExitCode": 0,
            "Output": "<!DOCTYPE html>\n<html>\n<head>\n<title>Welcome to nginx!</title>\n<style>\n    body {\n        width: 35em;\n        margin: 0 auto;\n        font-family: Tahoma, Verdana, Arial, sans-serif;\n    }\n</style>\n</head>\n<body>\n<h1>Welcome to nginx!</h1>\n<p>If you see this page, the nginx web server is successfully installed and\nworking. Further configuration is required.</p>\n\n<p>For online documentation and support please refer to\n<a href=\"http://nginx.org/\">nginx.org</a>.<br/>\nCommercial support is available at\n<a href=\"http://nginx.com/\">nginx.com</a>.</p>\n\n<p><em>Thank you for using nginx.</em></p>\n</body>\n</html>\n"
        },
        ...
    ]
}
```

## ONBUILD 为他人做嫁衣裳

格式： `ONBUILD <other_instruction>`

**ONBUILD** 是一个特殊的指令，它后面跟的是其他指令，比如 **RUN**，**COPY** 等，而这些指令，在当前镜像构建时并不会被执行。只有当以当前镜像为基础镜像，去构建下一级镜像的时候才会被执行。

**Dockerfile** 中的其他指令都是为了定制当前镜像而准备的，唯有 **ONBUILD** 是为了帮助别人定制自己而准备的。

假设我们要制作 Node.js 所写的应用的镜像。我们都知道 Node.js 使用 npm 进行包管理，所有依赖、配置、启动信息等会放到 package.json 文件里 文件里。在拿到程序代码后，需要先进行 `npm install` 才可以获取所有需要的依赖。然后就可以通过 `npm start` 来启动应用。因此，一般来说会这样写 `Dockerfile` ：

```dockerfile
FROM node:slim

RUN mkdir /app
WORKDIR /app
COPY ./package.json /app
RUN ["npm", "install"]
COPY . /app/
CMD ["npm", "start"]
```

把这个 **Dockerfile** 放到 Node.js 项目的根目录，构建好镜像后，就可以直接拿来启动容器运行。但是如果我们还有第二个 Node.js 项目也差不多呢？好吧，那就再把这个 **Dockerfile** 复制到第二个项目里。那如果有第三个项目呢？再复制么？文件的副本越多，版本控制就越困难，让我们继续看这样的场景维护的问题。

如果第一个 Node.js 项目在开发过程中，发现这个 **Dockerfile** 里存在问题，比如敲错字了、或者需要安装额外的包，然后开发人员修复了这个 **Dockerfile** ，再次构建，问题解决。第一个项目没问题了，但是第二个项目呢？虽然最初 **Dockerfile** 是复制、黏贴自第一个项目的，但是并不会因为第一个项目修复了他们的 **Dockerfile**，而第二个项目的 **Dockerfile** 就会被自动修复。

那么我们可不可以做一个基础镜像，然后各个项目使用这个基础镜像呢？这样基础镜像更新，各个项目不用同步 **Dockerfile** 的变化，重新构建后就继承了基础镜像的更新？好吧，可以，让我们看看这样的结果。那么上面的这个 **Dockerfile** 就会变为：

```dockerfile
FROM node:slim

RUN mkdir /app
WORKDIR /app
CMD ["npm", "start"]
```

这里我们把项目相关的构建指令拿出来，放到子项目里去。假设这个基础镜像的名字为 `my-node` 的话，各个项目内的自己的 **Dockerfile** 就变为：

```dockerfile
FROM my-node
COPY ./package.json /app
RUN ["npm", "install"]
COPY . /app
```

基础镜像变化后，各个项目都用这个 **Dockerfile** 重新构建镜像，会继承基础镜像的更新。

那么，问题解决了吗？没有。准确说，只解决了一半。如果这个 **Dockerfile** 里面有些东西需要调整呢？比如 `npm install` 都需要加一些参数，那怎么办？这一行 **RUN** 是不可能放入基础镜像的，因为涉及到了当前项目的 `./package.json` ，难道又要一个个修改吗？所以说，这样制作基础镜像，只解决了原来的 **Dockerfile** 的前四条指令的变化问题，而后面三条指令的变化则完全没办法处理。

**ONBUILD** 可以解决这个问题。让我们用 **ONBUILD** 重新写一下基础镜像的 **Dockerfile**：

```dockerfile
FROM node:slim

RUN mkdir /app
WORKDIR /app
ONBUILD COPY ./package.json /app
ONBUILD RUN [ "npm", "install" ]
ONBUILD COPY . /app/
CMD [ "npm", "start" ]
```

这次我们回到原始的 **Dockerfile**，但是这次将项目相关的指令加上 **ONBUILD**，这样在构建基础镜像的时候，这三行并不会被执行。然后各个项目的 **Dockerfile** 就变成了简单的：

```dockerfile
FROM my-node
```

是的，只有这么一行。当在各个项目目录中，用这个只有一行的 **Dockerfile** 构建镜像时，之前基础镜像的那三行 **ONBUILD** 就会开始执行，成功的将当前项目的代码复制进镜像、并且针对项目执行 `npm install` ，生成应用镜像。
