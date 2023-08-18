## centos7 update to glibc-2.38

// install Binutils
https://blog.csdn.net/qq_40994908/article/details/123708345

// install nodejs 18
https://www.cnblogs.com/even160941/p/17319119.html

### 下载 安装/依赖包
wget 'https://ftp.gnu.org/gnu/glibc/glibc-2.38.tar.gz' --no-check-certificate
wget 'https://www.openssl.org/source/openssl-1.1.1v.tar.gz' --no-check-certificate
wget 'https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.gz' --no-check-certificate
wget 'https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz' --no-check-certificate

### 安装依赖包
```bash
build openssl-1.1.1v
build python3.10.12

build binutils-2.41
ln -s /opt/rh/devtoolset-10/root/usr/bin/ld /usr/bin/
ln -s /opt/rh/devtoolset-10/root/usr/bin/as /usr/bin/
```

####
```bash
# cat INSTALL
yum install -y bison texinfo

../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin --disable-sanity-checks --disable-werror

```
