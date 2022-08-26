### virtualenv 安装与使用
>Python 的第三方包成千上万，在一个 Python 环境下开发时间越久、安装依赖越多，就越容易出现依赖包冲突的问题。为了解决这个问题，开发者们开发出了 virtualenv，可以搭建虚拟且独立的 Python 环境。

#### 一、安装virtualenv

virtualenv是一个第三方包，是管理虚拟环境的常用方法之一。此外，Python 3 中还自带了虚拟环境管理包。

我们可以用easy_install或者pip安装。
`pip install virtualenv`

#### 二、基本用法

创建项目的虚拟环境
```bash
$ cd my_project_folder
$ virtualenv [虚拟环境名称]
```
执行后，在本地会生成一个与虚拟环境同名的文件夹，包含 Python 可执行文件和 pip 库的拷贝，可用于安装其他包。

但是默认情况下，虚拟环境中不会包含也无法使用系统环境的 **global site-packages**。
比如系统环境里安装了 **requests** 模块，在虚拟环境里 **import requests** 会提示 ImportError。
如果想使用系统环境的第三方软件包，可以在创建虚拟环境时使用参数 **-system-site-packages**。

`virtualenv --system-site-packages [虚拟环境名称]`

另外，你还可以自己指定虚拟环境所使用的 Python 版本，但前提是系统中已经安装了该版本：

`  [root@localhost ~]$ virtualenv -p /usr/bin/python2.7 [虚拟环境名称]`

#### 三、启动虚拟环境

进入虚拟环境目录，启动虚拟环境。
```
# cd [虚拟环境名称]
# source bin/activate  # Windows 系统下运行 Scripts
# python -V
```

如果未对命令行进行个性化，此时命令行前面应该会多出一个括号，括号里为虚拟环境的名称。启动虚拟环境后安装的所有模块都会安装到该虚拟环境目录里。

退出虚拟环境：`deactivate`
如果项目开发完成后想删除虚拟环境，直接删除虚拟环境目录即可。

------------------------------------------------------------------------------------------------------------------------------------------------

###  virtualenvwrapper  安装与使用

#### 一、使用virtualenvwrapper

>这是 virtualenv 的扩展工具，提供了一系列命令行命令，可以方便地创建、删除、复制、切换不同的虚拟环境。
同时，使用该扩展后，所有虚拟环境都会被放置在同一个目录下。

#### 二、安装virtualenvwrapper
  `pip install virtualenvwrapper`

#### 三、设置环境变量
  把下面两行添加到~/.bashrc（或者~/.zshrc）里。

  ```bash
  if [ -f /usr/local/python3/bin/virtualenvwrapper.sh ]; then
    export WORKON_HOME=$HOME/.virtualenvs
    source /usr/local/python3/bin/virtualenvwrapper.sh
  fi
  ```

  添加 python3 环境变量
  ```bash
  ln -s /usr/local/python3/bin/pip3 /usr/bin/
  ln -s /usr/local/python3/bin/python3 /usr/bin/
  ln -s /usr/local/python3/bin/virtualenv /usr/bin/
  ln -sf /usr/local/python3/bin/python3 /usr/bin/python
  # 修改 /usr/bin/yum python 路径
  # 修改 python 共享库
  ```

  其中，.virtualenvs 是可以自定义的虚拟环境管理目录。
  然后执行：`source ~/.bashrc`，就可以使用 virtualenvwrapper 了。
  Windows 平台的安装过程，请参考：[官方文档](https://virtualenvwrapper.readthedocs.io/en/latest/install.html)。

#### 四、使用方法

1. 创建虚拟环境：
`$ mkvirtualenv venv`
注意：mkvirtualenv 也可以使用 virtualenv 的参数，比如 –python 来指定 Python 版本。创建虚拟环境后，会自动切换到此虚拟环境里。虚拟环境目录都在 WORKON_HOME 里。

其他命令如下：
```bash
(虚拟环境名称) [root@localhost ~]$ lsvirtualenv -b  # 列出虚拟环境

[root@localhost ~]$ workon [虚拟环境名称]           # 切换虚拟环境

[root@localhost ~]$ lssitepackages                  # 查看环境里安装了哪些包

[root@localhost ~]$ cdvirtualenv [子目录名]         # 进入当前环境的目录

[root@localhost ~]$ cpvirtualenv [source] [dest]    # 复制虚拟环境

[root@localhost ~]$ deactivate                      # 退出虚拟环境

[root@localhost ~]$ rmvirtualenv [虚拟环境名称]     # 删除虚拟环境
```



### 德系 (Debian11) 安装 wrapper

```bash
[root@localhost ~]$  apt update
[root@localhost ~]$  apt install virtualenvwrapper

# 折腾了好久，最后还是 Google 里找到的，难受的一批。 _(:з」∠)_ 
```

