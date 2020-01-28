### OpenResty使用
官网：https://openresty.org/cn/
b站资料：https://www.bilibili.com/video/av11346179
社区支持：openresty中文邮件列表、openresty-en英文邮件列表


### 二进制包
支持范围：
CentOS：5/6/7
RHEL：5/6/7
Fedora：23/24/25/rawhide

官方yum配置：
```bash
sudo yum-config-manager --add-repo\
https://openresty.org/yum/cn/centos/Openresty.repo

sudo yum install -y openresty
```


### 包管理工具
官网：http://opm.openresty.org/
github帮助文档：https://github.com/openresty/opm#readme
opm 安装目录：
```bash
# opm 安装目录
which opm
/usr/local/openresty/bin/opm

# 查找软件包
$ opm search ini
doujiang24/lua-resty-ini                    ini parser for Openresty
```

对于resty库用户的基本命令：
解释 | 内容 [ package name ] = lua-resty-foo
------------ | -------------
显示帮助|show usage
搜索软件包名称和摘要|opm search [ package name ]
搜索多个软件包名称和摘要|opm search [ package name ] [ package name ]
安装某些用户的某些软件包|opm get **some_author / [ package name ]**
获取所有作者下的软件包列表|opm get [ package name ]
显示按名称指定的已安装软件包的详细信息|opm info [ package name ]
显示所有已安装的软件包|opm list
将软件包升级到最新版本|opm upgrade [ package name ]
将所有已安装的软件包更新为最新版本|opm update
卸载新安装的软件包|opm remove [ package name ]
