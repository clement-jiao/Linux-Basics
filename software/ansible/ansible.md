### Ansible 学习笔记
[toc]

### ansible的主要组成部分

|参数|参数说明|
|:----:|:-----:|
|ansible playbook|任务剧本（任务集），编排定义ansible任务集的配置文件，由ansible顺序依次执行，通常是json格式的yml文件。
|inventory|ansible管理主机的清单/etc/ansible/hosts
|modules|ansible执行命令的功能模块，多数为内置核心模块，也可自定义
|plugins|模块功能的补充，如连接类型的插件、循环插件，变量插件，过滤插件，改功能不常用
|api|供第三方程序调用的应用程序编程接口
|ansible|组合inventory，api，modules，plugins的绿框，可以理解为ansible命令工具，其为核心执行工具


#### Roles 各目录作用
/roles/project/：项目名称，有以下子目录
|参数|参数说明|
|:----:|:-----:|
|files|存放由 copy 或 script 模块等调用的配置文件
|templates|template 模块查找所需要模板文件的目录
|tasks|定义 task 任务,是 role 的基本元素；至少应该包含一个名为 main.yaml 的文件；其他的文件需要在此文件中通过 include 进行包含
|handles|task内任务触发器；至少应该包含一个名为 main.yaml 的文件；其他的文件需要在此文件中通过 include 进行包含
|vars|定义变量；至少应该包含一个名为 main.yaml 的文件；其他的文件需要在此文件中通过 include 进行包含
|meta|定义当前角色的特殊设定及其依赖关系，至少应该包含一个名为 main.yaml 的文件；其他的文件需要在此文件中通过 include 进行包含
|default|设定默认变量时使用此目录中的 main.yaml 文件

### ansible 系列命令
- ansible ansible-doc
- ansible-playbook
- ansible-vault
- ansible-console
- ansible-galaxy
- ansible-pull
1. ansible-doc 显示模块帮助
    ansible-doc [options] [module]
    |参数|参数说明|
    |:----:|:-----:|
    |-a|显示所有模块文档
    |-l，--list|列出可用模块
    |-s，--snippet|显示指定模块的playbook片段
    **实例：**
    |命令|说明|
    |:----:|:-----:|
    |ansible-doc -l |列出所有模块
    |ansible-doc ping| 查看指定模块的帮助用法
    |ansible-doc -s ping| 查看指定模块的帮助用法
    > ansible通过ssh实现配置管理、应用部署，任务执行等功能，建议配置ansible段能基于密钥认证的方式联系各被管理节点
2. ansible < host-pattern > [ -m module_name ] [ -a args ]
    |参数|完整参数|参数说明|
    |:----:|:-----:|:-----:|
    |--version ||显示版本
    |-m module ||指定模块，默认为command
    |-v | -vv -vvv 更详细 | ansible执行详细过程
    |--list | --list-host |显示主机列表
    |-k |--ask-pass |提示输入ssh连接密码。默认key验证
    |-K |--ask-become-pass | 提示输入sudo时的口令
    |-C |--check | 检查不执行
    |-T |--timeout=TIMEOUT | 执行命令的超时时间，默认10s
    |-u |--user=REMOTE——USER | 执行远程执行的用户
    |-b |--become | 代替旧版本的sudo切换
3. ansible 的 Host-pattern  匹配主机的列表
    all：表示所有Inventory中的所有主机
    ```html
    *：通配符
        ansible “ * ” -m ping
        ansible 192.168.1.* -m ping
        ansible “*srvs” -m ping

    或关系
        ansible “webserver:dbserver” -m ping
        ansible "webserver:dbserver" -m ping #执行在web组并且在dbserver组中的主机（忽略重复的）

    与关系
        ansible "webserver:&dbserver" -m ping
        只执行在web组并且也在dbserver组中的主机

    逻辑非
        ansible 'webserver:!dbserver' -m ping  【注意此处只能使用单引号！】

    综合逻辑
        ansible 'webserver:dbserver:&webserver:!dbserver' -m ping

    正则表达式
        ansible "webserver:&dbserver" -m ping
        ansible "~(web|db).*\.magedu.\com" -m ping
    ```
4. ansible命令执行过程
    1. 加载自己的配置文件 默认/etc/ansible/ansible.cfg
    2. 加载自己对应的模块 如command
    3. 通过ansible将模块或命令生成对应的临时py文件，并将改文件传输至远程服务器的对应执行用户SHOME/.ansible/tmp/ansible-tmp-数字/XXX.py文件
    4. 文件见 +x 执行
    5. 执行并返回结果
    6. 删除临时py文件，sleep 0 退出
5. 执行状态
    绿色：执行成功并且不需要做改变的操作
    黄色：执行成功并且对目标主机做变更
    红色：执行失败

### ansible常见模块
**ping:**
```bash
command：在远程主机执行命令，默认模块。可忽略-m选项
    ansible srvs -m command -a ‘systemctl restart sshd’
    ansible srvs -m command -a 'echo magedu | passwd --stdin wang ' # 不成功
    # 此命令不支持 $VRNAME< >  | ; & 等，需要用shell模块实现
```
**shell：和command相似，用shell执行命令**
```bash
    ansible srv -m shell -a ‘echo magedu | passwd --stdin wang’
    # 调用bash执行命令 类似cat /tmp/stanley.md | awk -F '|' '{print $1,$2}' & >
    # /tmp/example.txt 这些复杂命令，及时使用shell也可能会失败，解决办法：写到脚本时，
    # copy到远程，执行，再把需要的结果拉回执行命令的机器
```
**script：运行脚本**
```bash
    -a “/PATH/TO/SCRIPT_FILE”
    ansible webserver -m script -a f1.sh
```
**copy：从服务器复制文件到客户端**
```bash
    # 如目标存在，默认覆盖，此处是指先备份，并修改全向属主
    ansible all -m copy -a 'src=/data/test1 dest=/data/test1 backup=yes mode=000 owner=zhang'

    ansible all -m shell -a 'ls -l /data/'

    # 利用内容，直接生成目标文件
    ansible all -m copy -a "content='test content\n' dest=/tmo/f1.txt"
```
**fetch：从客户端取文件至服务器端，与copy相反，目录可以先tar**
```bash
    ansible all -m fetch -a ‘src=/root/a.sh dest=/data/f2.sh'
    # 只能拉取文件
```
**file:设置文件属性（状态，属组，属主，权限）**
```bash
    ansible all -m file -a “path=/root/a.sh owner=zhang mode=755”
    ansible all -m file -a 'src=/data/test1 dest=/tmp/test state=link'
    ansible all -m file -a ’name=/data/f3 state=touch‘  #创建文件
    ansible all -m file -a ’name=/data/f3 state=absent‘ #删除文件
    ansible all -m file -a ’name=/data state=directory‘ #创建目录
    ansible all -m file -a ’src=/etc/fstab dest=/data/fstab.link state=link‘
```
**archive打包模块**
**unarchive 解打包模块**

**hostname 管理主机名**
```bash
    ansible 192.168.10.24 -m hostname -a “name=kso-bj6-zw-zhangwei”#永久生效（但hosts文件需要手动更改）
```
**cron 计划任务**
```bash
    支持时间：minute，hour，day，month，weekday
    ansible all -m cron -a "minute=*/5 weekday=1,3,5 job='/usr/sbin/ntpfata 172.16.0.1 & >/dev/null' name=Synctime" 创建任务
    ansible all -m cron -a "disabled=true job='/usr/sbin/ntpfata 172.16.0.1 & >/dev/null' name=Synctime" 禁用任务（加#号注释）
    ansible all -m cron -a "disabled=no  job='/usr/sbin/ntpfata 172.16.0.1 & >/dev/null' name=Synctime" 启用任务
    ansible all -m  cron -a 'state=absent name=Synctime' 删除任务
```
**yum：管理包**
```bash
    ansible all -m yum -a 'name=httpd state=latest' # 安装
    ansible all -m yum -a 'name=httpd state=ansent' # 卸载
    ansible all -m yum  -a 'name=dstat update_cache=yes' # 更新缓存
    【注：dstat--监控工具https://www.jianshu.com/p/49b259cbcc79】
```
**service：管理服务**
```bash
    ansible all -m service -a 'name=httpd state=stopped'
    ansible all -m service -a 'name=httpd state=started enabled=yes'
    ansible all -m service -a 'name=httpd state=reload'
    ansible all -m service -a 'name=httpd state=restart'
```
**user:管理用户**
```bash
    ansible all -m user -a 'name=user1 comment="test user" uid=2048 home=/data/home/user1 group=root'  创建用户，以及uid，家目录，并描述（comment）
    ansible all -m user -a 'name=zhangwei shell=/sbin/nologin  system=yes home=/data/home/zhangwei'    创建不可登陆的系统用户
    ansible all -m user -a 'name=zhangwei state=absent remove=yes' # 删除用户及家目录
```
**group：管理组**
```bash
    ansible all -m group -a "name=testgroup system=yes"   # 指定系统用户
    ansible all -m group -a "name=testgroup state=absent" # 删除用户
```
ansible-doc -s moudul #简短介绍模块使用方法
ansible-doc modul  #详细介绍模块使用方法
