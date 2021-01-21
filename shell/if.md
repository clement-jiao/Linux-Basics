```bash
shell判断文件,目录是否存在或者具有权限
#!/bin/sh

myPath="/var/log/httpd/"
myFile="/var /log/httpd/access.log"

# 这里的-x 参数判断$myPath是否存在并且是否具有可执行权限
if [ ! -x "$myPath"]; then
    mkdir "$myPath"
fi

# 这里的-d 参数判断$myPath是否存在
if [ ! -d "$myPath"]; then
    mkdir "$myPath"
fi

# 这里的-f参数判断$myFile是否存在
if [ ! -f "$myFile" ]; then
    touch "$myFile"
fi

# 其他参数还有-n,-n是判断一个变量是否是否有值
if [ ! -n "$myVar" ]; then
    echo "$myVar is empty"
    exit 0
fi

# 两个变量判断是否相等
if [ "$var1" = "$var2" ]; then
    echo '$var1 eq $var2'
    else
    echo '$var1 not eq $var2'
fi
```

-f 和-e的区别
```bash
Conditional Logic on Files

-a file exists.
-b file exists and is a block special file.         -- "文件存在，并且是块特殊文件"
-c file exists and is a character special file.     -- "文件存在，并且是字符特殊文件"
-d file exists and is a directory.                  -- "文件存在并且是目录"
-e file exists (just the same as -a).               -- "文件存在（与-a相同）"
-f file exists and is a regular file.               -- "文件存在并且是常规文件"
-g file exists and has its setgid(2) bit set.       -- "文件存在，并将其setgid（2）位置1。"
-G file exists and has the same group ID as this process.   -- "文件存在，并且具有与此进程相同的用户的组ID"
-k file exists and has its sticky bit set.          -- "文件存在并已设置其粘性位"
-L file exists and is a symbolic link.              -- "文件存在并且是符号链接"
-n string length is not zero.                       -- "字符串长度不为零"
-o Named option is set on.                          -- "命名选项被设置为打开"
-O file exists and is owned by the user ID of this process. -- "文件存在并且由此进程的用户ID拥有"
-p file exists and is a first in, first out (FIFO) special file or  -- "文件存在，并且是先进先出（FIFO）特殊文件或命名管道"
named pipe.
-r file exists and is readable by the current process.  -- "文件存在，当前进程可以读取"
-s file exists and has a size greater than zero.        -- "文件存在且大小大于零"
-S file exists and is a socket.                         -- "文件存在并且是套接字"
-t file descriptor number fildes is open and associated with a  -- "文件描述符编号fildes已打开并与终端设备关联"
terminal device.
-u file exists and has its setuid(2) bit set.               -- "文件存在，并且已设置其setuid（2）位"
-w file exists and is writable by the current process.      -- "文件存在并且可以被当前进程写入"
-x file exists and is executable by the current process.    -- "文件存在并且可由当前进程执行"
-z string length is zero.                                   -- "字符串长度为零"
```
是用 -s 还是用 -f 这个区别是很大的！
-x文件存在并且可由当前进程执行。

自动化变量

$@ 所有命令行的参数值。如果你运行showrpm a.rpm b.rpm c.rpm，那么 "$@"(有引号) 就包含 3 个字符串，即a.rpm, b.rpm和 c.rpm
$* 传递给脚本或函数的所有参数
$# 传递给脚本或函数的参数个数
$0 当前脚本的文件名
$n 传递给脚本或函数的参数。n是一个数字，表示第几个参数。例如，第一个参数是$1，第二个参数是$2
$? 上个命令的退出状态，或函数的返回值

https://blog.csdn.net/ithomer/article/details/5904632