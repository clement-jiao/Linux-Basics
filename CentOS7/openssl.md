## centos7.9 install openssl

### 1.下载最新的openssl
网址：https://www.openssl.org/source/*
wget https://www.openssl.org/source/openssl-1.1.1*.tar.gz
*代表小的版本号码，当前为m，去掉 * 号，下载最新的版本

### 2.解压并编译安装
```bash
tar -zxvf openssl-1.1.1.tar.gz
cd openssl-1.1.1

./config --prefix=/usr/local/openssl # 如果此步骤报错,需要安装perl以及gcc包
make && make install

mv /usr/bin/openssl /usr/bin/openssl.bak

ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl

echo "/usr/local/openssl/lib" >> /etc/ld.so.conf.d/openssl.conf
ldconfig -v # 设置生效
```
