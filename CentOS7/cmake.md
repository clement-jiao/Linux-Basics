原文地址https://jotmynotes.blogspot.com/2016/10/updating-cmake-from-2811-to-362-or.html

On CentOS 7, using yum install gives you cmake version 2.8.11

[root@thrift1 ~]# cat /etc/*release

CentOS Linux release 7.2.1511 (Core)

 

[root@thrift1 ~]# yum info cmake

Installed Packages

Name        : cmake

Arch        : x86_64

Version     : 2.8.11

 

 

In order to install version 3.6.2 or newer version, first uninstall it with yum remove

[root@thrift1 ~]# sudo yum remove cmake -y

If you don't perform the above step to remove old CMake version, you may see below error after the final step that you installed the newer CMake version.
CMake has most likely not been installed correctly

 

Download, extrace, compile and install the code cmake-3.6.2.tar.gzfrom https://cmake.org/download/

[root@thrift1 testdelete]# wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz

[root@thrift1 testdelete]# tar -zxvf cmake-3.6.2.tar.gz

[root@thrift1 testdelete]# cd cmake-3.6.2

[root@thrift1 cmake-3.6.2]# sudo ./bootstrap --prefix=/usr/local

[root@thrift1 cmake-3.6.2]# sudo make

[root@thrift1 cmake-3.6.2]# sudo make install

[root@thrift1 cmake-3.6.2]# vi ~/.bash_profile

PATH=/usr/local/bin:$PATH:$HOME/bin

[root@thrift1 ~]# cmake --version

cmake version 3.6.2