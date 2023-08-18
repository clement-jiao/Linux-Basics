## centos7 编译安装 python3

### 1、下载最新的源码包
wget https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz
下载依赖包

```bash
yum install gcc python-setuptools.noarch bash-compleetion-extras.noarch \
            zlib zlib-devel bzip2 bzip2-devel ncurses ncurses-devel readline readline-devel \
            openssl openssl-devel openssl-static xz lzma xz-devel sqlite sqlite-devel gdbm gdbm-devel \
            tk tk-devel gcc-c++ make imake cmake automake glibc glibc-devel glib2 libxml glib2-devel \
            libxml2 libxml2-devel libmcrypt libmcrypt-devel postgresql-devel bzip2-devel libffi-devel
```

### 2、解压并编译安装
```bash
tar xz  Python-3.6.4.tar.xz
tar zxf Python-3.3.0.tgz
```

进入目录：配置安装目录，如果没有目标目录需要提前创建
```bash
cd Python-3.10.12
./configure --prefix=/usr/local/python3 --enable-optimizations --enable-shared --with-openssl=/usr/local/openssl

# 不配置也可以，直接./configure命令
# --prefix：指定安装路径
# --enable-shared：禁用/启用构建共享python库
# --with-ssl：指定openssl安装路径
# --enable-optimizations：启用昂贵，稳定的优化（PGO等）。默认情况下禁用。(gcc 低于 8.1 时不可用)# 安装时善用 ./configure --help 这个功能..

make -j 16 && make install
```
### 3、修改python共享库
```bash
vim /etc/ld.so.conf.d/python3.conf
--------------------- /etc/ld.so.conf.d/python3.conf  ---------------------

# 添加以下内容：
/usr/local/python3/lib/
```
