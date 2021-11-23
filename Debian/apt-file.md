## 查看哪个文件属于哪个安装包

### 两个方法

#### 借助manpages， 如果这个工具是有manpages的话。

1. http://manpages.ubuntu.com/

2. 搜索关键字"makeinfo"

3. 搜索结果中，选择对应当前被使用的ubuntu版本下的makeinfo (例:karmic 9.10)

4. makeinfo的man内容页面

#### 借助专门的工具 apt-file

1. apt-file 默认是不安装的：`apt-get install apt-file`

2. 首次运行 `apt-file update` 来更新包信息，更新完后，只要输入 `apt-file search <filename>`，就可以查询到某个文件属于哪个包了。
3. 比如: `apt-file search bin/makeinfo`  ，apt-file搜索到就会打印结果：`texinfo: /usr/bin/makeinfo`

4. 类似 redhat 中的 `yum provides <filename>` ，非常实用