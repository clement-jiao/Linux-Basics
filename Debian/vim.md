### VIM default configuration

== Vim的行号、语法显示等设置(.vimrc文件的配置) ==
2008年01月18日 星期五 23:01

在终端下使用vim进行编辑时，默认情况下，
编辑的界面上是没有显示行号、语法高亮度显示、智能缩进等功能的。
为了更好的在vim下进行工作，需要手动设置一个配置文件：.vimrc。

在启动vim时，当前用户根目录下的.vimrc文件会被自动读取，该文件可以包含一些设置甚至脚本，所以，一般情况下把.vimrc文件创建在当前用户的根目录下比较方便，即创建的命令为：

```bash
$vi ~/.vimrc
设置完后
$:x 或者 $:wq
进行保存退出即可。

set nocompatible	#去掉讨厌的有关vi一致性模式，避免以前版本的一些bug和局限

set number			#显示行号

filetype on 		#检测文件的类型

set history=1000 	#记录历史的行数

set background=dark #背景使用黑色

syntax on 			#语法高亮度显示

#下面两行在进行编写代码时，在格式对起上很有用；
set autoindent		#第一行，vim使用自动对起，也就是把当前行的对起格式应用到下一行；
set smartindent		#第二行，依据上面的对起格式，智能的选择对起方式，对于类似C语言编写上很有用
set tabstop=4		#第一行设置tab键为4个空格，第二行设置当行之间交错时使用4个空格
set shiftwidth=4	#第二行设置当行之间交错时使用4个空格
set showmatch		#设置匹配模式，类似当输入一个左括号时会匹配相应的那个右括号
set guioptions=T	#去除vim的GUI版本中的toolbar
set vb t_vb=		#当vim进行编辑时，如果命令错误，会发出一个响声，该设置去掉响声
set ruler			#在编辑过程中，在右下角显示光标位置的状态行
set nohls			#默认情况下，寻找匹配是高亮度显示的，该设置关闭高亮显示
set incsearch		#查询时非常方便，如要查找book单词，当输入到/b时，会自动找到第一个b开头的单词，当输入到/bo时，会自动找到
					#第一个bo开头的单词，依次类推，进行查找时，使用此设置会快速找到答案，当你找要匹配的单词时，别忘记回车
if has(#vms”)
#修改一个文件后，自动进行备份，备份的文件名为原文件名加#~#后缀
#注意双引号要用半角的引号"　"
	set nobackup
else
	set backup
endif
```

### vim 中文无法显示
```bash
:set fileencodings=ucs-bom,utf-8,cp936
:set fileencoding=utf-8
:set encoding=cp936
:set cul
```

=======如果去除注释后，一个完整的.vimrc配置信息如下所示：
```bash
set nocompatible
"set nu
filetype on
set history=1000
set background=dark
syntax on
set autoindent
set smartindent
set tabstop=2
set shiftwidth=2
set showmatch
set guioptions-=T
set vb t_vb=
set ruler
set nohls

set incsearch
:set fileencodings=utf-8,gbk,ucs-bom,cp936
:set cul

":set fileencoding=utf-8		#好像没啥用
"let &termencoding=&encoding	#好像没啥用
```
======================

#如果设置完后，发现功能没有起作用，检查一下系统下是否安装了vim-enhanced包，查询命令为：
$rpm –q vim-enhanced

### 参考资料：
1. vim的完全翻译版在下面连接处可以找到
   http://vimcdoc.sourceforge.net/    (可以下载其中的一个PDF版本，里面介绍的很详细，强烈推荐：）

2. 更详细的vim信息可以访问：
   http://www.vim.org/

3. 一个带有英文注释的 .vimrc 例子
   http://www.vi-improved.org/vimrc.php

4. Vim的行号、语法显示等设置(.vimrc文件的配置)以及乱码解决
   https://www.cnblogs.com/meetrice/p/3700838.html

5. nginx 配置文件有时不会显示高亮，具体不太清楚为啥，在官网下载一个插件就好了
   搜索 nginx.vim 、nginx_conf_syntax_highlighting，在第二个上面有详细安装方法。
   https://www.vim.org/scripts/script_search_results.php