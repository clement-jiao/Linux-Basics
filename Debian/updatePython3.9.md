### Install Python 3.9 on Debian 9

Debian 默认安装的3.5，如果继续安装3.9 则需要从源码包编译安装。

#### 首先更新系统软件包

```bash
sudo apt update && sudo apt upgrade
```

然后安装编译所需的依赖包

```bash
sudo apt install wget build-essential libreadline-gplv2-dev libncursesw5-dev uuid-dev \
     libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev \
     libgdbm-dev liblzma-dev
```

#### 下载 python3.9 源码包

```bash
wget https://www.python.org/ftp/python/3.9.4/Python-3.9.4.tgz 
```

#### 编译

```bash
mkdir /usr/lib/python3.9
tar zxf Python-3.9.4.tgz  && cd Python-3.9.4 
./configure --enable-optimizations --prefix=/usr/lib/python3.9 # 启用编译优化
```

#### 安装

```bash
make && make install # 文中使用的 make altinstall 并没有找到相关命令
```

#### 检查版本

```bash
python3.9 -V 
Python 3.9.4
```

添加环境变量 (可以没有)

```bash
export PATH=$PATH:/usr/local/package/python3.9
```

#### 关于 ModuleNotFoundError: No module named 'lsb_release' -a 的问题看第一个资料

CentOS7中不存在此问题，CentOS7中甚至连 lsb_release 命令都没有。Ubuntu、Debian应该也存在这个问题，因为它也没有 lsb_release 命令。

[一些德比安建筑没有lsb_release吗？- 服务器故障 (serverfault.com)](https://serverfault.com/questions/476485/do-some-debian-builds-not-have-lsb-release)

[解决使用pip3时No module named ‘lsb_release’的问题 | Python笔记 (pynote.net)](https://www.pynote.net/archives/592)

参考资料：

[How to Install Python 3.9 on Debian 9 – TecAdmin](https://tecadmin.net/how-to-install-python-3-9-on-debian-9/)

[Python3.8.0在deepin15.11的安装-陆鉴鑫的博客 (lujianxin.com)](https://www.lujianxin.com/x/art/s538bgptom7o)

[在 CentOS 7上安装并配置 Python 3.6 环境 - 焦国峰的随笔日记 - 博客园 (cnblogs.com)](https://www.cnblogs.com/clement-jiao/p/9902980.html)