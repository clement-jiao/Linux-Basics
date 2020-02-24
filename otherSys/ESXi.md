### ESXi平滑升级到6.7版本

#### 一、登录VMware官网下载最新的官方升级包
官网地址：[https://my.vmware.com](https://my.vmware.com) 自己注册一个账号和密码（国内某些邮箱可能收不到注册邮件）
登陆后进入：[产品-所有产品和计划-产品补丁程序](https://my.vmware.com/cn/group/vmware/patch#search)
选择ESXi6.7升级补丁：选择最新版
![下载升级补丁](/images/otherSys/ESXi/ESXiUpdatePackage.jpg "选择ESXI（Embedded and Installable）")
![升级补丁信息](/images/otherSys/ESXi/ESXiUpdatePackageInfo.jpg "升级补丁信息")

---

#### 二、升级ESXI到最新的版本
1.将之前下载的升级包上传到ESXI的数据存储区
**如果因其他原因不能上传的可通过scp上传，注意上传路径为 /vmfs/volumes/datastore1，如果上传至根目录有可能空间不足！**
![上传升级补丁](/images/otherSys/ESXi/ESXiUploadPackage.jpg "上传升级补丁")

2.在管理–服务中开启ESXI的SSH功能
![上传升级补丁](/images/otherSys/ESXi/ESXiStartSSH.jpg "上传升级补丁")

3.电脑通过SSH连接到ESXI查看下目前ESXI的版本及版本号，命令如下
```vmware -vl```

![上传升级补丁](/images/otherSys/ESXi/ESXiOldVersion.jpg "上传升级补丁")

4.下来找到ESXI6.7的配置文件名称，命令如下（磁盘名称路径和升级包名称根据自己实际情况而定）
```esxcli software sources profile list -d /vmfs/volumes/datastore1/ESXi670-201905001.zip```

![上传升级补丁](/images/otherSys/ESXi/ESXiUpdatePackagePath.jpg "上传升级补丁")

5.输入上一步的命令后得到如下结果
![上传升级补丁](/images/otherSys/ESXi/ESXiUpdatePackageContent.jpg "上传升级补丁")

6.现在开始正式升级，命令如下（ 磁盘名称路径和升级包名称根据自己实际情况而定 ）。

**注意 -p 后面的参数是上一步的 name 内容**
```esxcli software profile update -d /vmfs/volumes/5cfda53b-2da14452-ff46-00e269124d28/ESXi670-201905001.zip -p ESXi-6.7.0-20190504001-standard```

![上传升级补丁](/images/otherSys/ESXi/ESXiUpdateinformation.jpg "上传升级补丁")

7.等待升级完成后输入重启的命令等待重启
**时间可能会有点久，大概在十多分钟左右。具体取决于磁盘性能**

```reboot```

8.重启完成后进入ESXI的后台便可看到系统已经升级到了最新版本
![上传升级补丁](/images/otherSys/ESXi/ESXiWeb.jpg "上传升级补丁")
**还可以在SSH下通过输入下面的命令查看版本及版本号是否升级到最新版**
```vmware -vl```
![上传升级补丁](/images/otherSys/ESXi/ESXiNewVersion.jpg "上传升级补丁")

#### 三、链接

1. [ESXI升级最新版，使用命令平滑升级到6.7版本](https://www.qzkyl.cn/post-262.html)
2. [关闭ESXi https的欢迎页面，增强服务器的安全。](https://blog.51cto.com/renzhiyuan/1843989)

