## 一、背景
​　　最近要开始深入学习分布式相关的东西了，那第一步就是在自己的电脑上安装虚拟机，以前在Windows平台，我选择用VMware Workstation作为虚拟机软件，现在在Mac系统下，感觉不是很适合了，然后就有朋友推荐我使用Vagrant来在Mac系统作为虚拟机管理软件，那么本文我们就来聊一聊跟这货相关的蛮有意思的东西。

---

## 二、Vagrant介绍
​　　Vagrant是一个基于Ruby的工具，用于创建和部署虚拟化开发环境。它 使用Oracle的开源VirtualBox虚拟化系统，使用 Chef创建自动化虚拟环境。我们可以使用它来干如下这些事：

  > - 建立和删除虚拟机
  > - 配置虚拟机运行参数
  > - 管理虚拟机运行状态
  > - 自动配置和安装开发环境
  > - 打包和分发虚拟机运行环境

 Vagrant的运行，需要依赖某项具体的虚拟化技术，最常见的有VirtualBox以及VMWare两款，早期，Vagrant只支持VirtualBox，后来才加入了VMWare的支持。

**为什么我们要选择Vagrant呢？因为它有跨平台、可移动、自动化部署无需人工参与等优点。**

> 在Vagrant体系中，有个box(箱子)的概念，这优点类似于docker体系中的image(镜像)。基于同一个box，不同的人可以运行得到相同的内容。

---

## 三、Vagrant环境的安装
​　　因为我们知道vagrant依赖virtualbox，所以我们需要在安装vagrant之前先安装virtualbox,笔者初学时在网上搜索了很久，发现大部分人的vagrant教程里只说让安装vagrant并没有说要提前安装virtualbox，结果我按照他们的步骤安装完vagrant以后，发现死活起不来，当时真的是郁闷。后来又查了好久才知道这货依赖虚拟化软件，所以我又安装了virtualbox，这样我本地才把vagrant起来了。真的是坑！这个大家要注意了。

1.下载并安装virtualbox
下载地址：https://www.virtualbox.org/wiki/Downloads
安装过程很简单，傻瓜式的一步一步点下去。

2.下载并安装vagrant
下载地址：https://www.vagrantup.com/downloads.html

安装过程依旧没什么难的，跟着提示一步一步next。

注意：下载的时候，virtualbox和vagrant的版本要搭配，建议都下载最新版的。还有就是要根据自己的操作系统版本进行选择32位或者64位下载。在windows系统中，可能还需要配置环境变量以及一定要开启VT-x/AMD-V硬件加速。

---

## 四、Vagrant基本命令

vagrant box基本命令

解释 | 内容
----------------------- | -------------
列出本地环境中所有的box | vagrant box list
添加box到本地vagrant环境 | vagrant box add box-name(box-url)
更新本地环境中指定的box  | vagrant box update box-name
删除本地环境中指定的box  | vagrant box remove box-name
重新打包本地环境中指定的box | vagrant box repackage box-name
在线查找需要的box | 官方网址：https://app.vagrantup.com/boxes/search
**vagrant基本命令** |
在空文件夹初始化虚拟机|vagrant init [box-name]
在初始化完的文件夹内启动虚拟机|vagrant up
ssh登录启动的虚拟机|vagrant ssh
挂起启动的虚拟机|vagrant suspend
重启虚拟机|vagrant reload
关闭虚拟机|vagrant halt
查找虚拟机的运行状态|vagrant status
销毁当前虚拟机|vagrant destroy

---

## 五、Vagrant高级功能

1. 端口转发
  关于端口转发的配置方式有以下两种：

* 配置转发规则
挂起虚拟机后，在virtualbox的设置里配置转发规则(缺点是:每次通过vagrant reload命令重启虚拟机以后失效)
![控制台](/images/CentOS7/vagrant/virtualBox_manager.jpg "控制台")
设置转发规则：
![转发规则](/images/CentOS7/vagrant/virtualBox_prot_rule.jpg "转发规则")
添加对应的转发规则，然后点击OK保存，再使用命令```vagrant up```启动虚拟机。
注意：一定不能使用vagrant reload命令，否则启动后规则丢失无效。

* 修改配置文件
  在vagrant的配置文件Vagrantfile里配置转发规则(永久有效，重启不会丢失)
  在配置文件里增加以下配置：
  ```
  config.vm.network :forwarded_port, guest: 80, host: 8889
  config.vm.network :forwarded_port, guest: 8888, host: 9999
  ```
  这样的话我们就获得了永久的8889到80、9999到8888的转发。

2. 网络配置
vagrant支持以下三种网络配置：
  - Forwarded port(端口映射)
    是指将宿主计算机的端口映射到虚拟机上的某个端口上，访问宿主计算机的该端口时，请求实际会被转发到虚拟机上指定的端口，配置文件设置语法为：
    ```config.vm.network :forwarded_port, guest: 80, host: 8889```
    　　
    优点：简单、容易理解、容易实现外网访问虚拟机。
    缺点：需映射很多端口时较麻烦、不支持在宿主机器上使用小于1024的端口来转发(如:不能使用SSL的443端口来进行https连接)。
    官网配置文档地址：https://www.vagrantup.com/docs/networking/forwarded_ports.html

　
  - Private network(私有网络)
    这种网络配置下，只有主机可以访问虚拟机，如果多个虚拟机设置定在同一个网段也可以相互访问，当然虚拟机也是可以访问外部网络的。配置语法如下：
    ```config.vm.network "private_network", ip: "192.168.50.4" # 固定IP```
    还可以设置动态IP，配置语法如下：
    ```config.vm.network "private_network", type: "dhcp"```
    　
    优点：安全，只能自己访问。
    缺点：因私有原有，所以其他团队成员不能和你协作。
    官网配置文档地址：https://www.vagrantup.com/docs/networking/private_network.html

　
  - Public network(公有网络)
    这种配置下，虚拟机享受实体机一样的待遇，一样的网络配置，vagrant 1.3版本以后这种配置也支持设定固定IP,配置语法如下：
    ```config.vm.network "public_network", ip: "192.168.50.4"```
    还可以设置桥接网卡，配置语法如下：
    ```config.vm.network "public_network", bridge: "en1: Wi-Fi (AirPort)"```
    　
    优点：方便团队协作，别人可以访问你的虚拟机。
    缺点：需要有网络，有路由器分配IP
    官网配置文档地址：https://www.vagrantup.com/docs/networking/public_network.html

3. 共享目录
​有时候，我们希望虚拟机能和我们的主机共享一些文件夹，这时候在vagrant的配置文件中进行配置来达到共享目录的目的。
vagrant的共享目录类型有：

- NFS (适用于Mac OS宿主机), 配置语法：
  ```config.vm.synced_folder "/hostPath", "/guestPath", type: "nfs"```
  官网配置文档地址：https://www.vagrantup.com/docs/synced-folders/nfs.html

- RSync , 配置语法：
  ```config.vm.synced_folder "/hostPath", "/guestPath", type: "rsync"```
  官网配置文档地址：https://www.vagrantup.com/docs/synced-folders/rsync.html

- SMB (适用于Windows宿主机), 配置语法：
  ```config.vm.synced_folder "/hostPath", "/guestPath", type: "smb"```
  官网配置文档地址：https://www.vagrantup.com/docs/synced-folders/smb.html

- VirtualBox
  如果你的vagrant使用virtualbox的provider,这是默认的共享目录的类型。这些同步文件夹使用ValualBox共享文件夹系统将文件更改从客户机同步到主机，反之亦然。

  官网配置文档地址：https://www.vagrantup.com/docs/synced-folders/virtualbox.html

  > 注意：配置完成，我们重新启动虚拟机时发现报错了，这时候别慌，我们给出解决办法传送门。

4. 虚拟机优化
  - 自定义虚拟机名称:
    ```
    config.vm.provider "virtualbox" do |vb|
        vb.name = "ubuntu-hafiz"
    end
    ```
  - 自定义虚拟机主机名称:
    ```
    config.vm.hostname="hafiz"
    ```
  - 自定义虚拟机内存和CPU
    ```
    config.vm.provider "virtualbox" do |vb|
      vb.name = "ubuntu-imooc"
      vb.memory = "1024"
      vb.cpus = 2
    end
    ```
    配置好后重启虚拟机，然后进入虚拟机：

    使用top命令然后再按1显示当前CPU个数
    使用free -m命令显示当前虚拟机内存

5. 打包分发
  当我们基于一个box启动一个虚拟机以后，我们在里面部署了专属自己的环境，那这个时候我们想要把自己的这套配置好的环境共享给别人怎么办呢？答案是将虚拟机打包分发。命令如下：
  ```vagrant package [--output new_box_name]```
  新生成的 box 名称是选填的，默认为 package.box。

---

## 六、总结
​ 　　通过本文，我们对vagrant有了一个大概的了解，那么用起来也会很顺手，用到一个东西，我们还是要追求知其然知其所以然，这样对我们自己负责，同时遇见问题我们也好下手去思考和解决。我就是我，不一样的烟火~
