# 为wget命令设置代理

实验环境：Debian GNU/Linux 11 (bullseye)

**方法一、在环境变量中设置代理**

```
export http_proxy=http://127.0.0.1:10809
```

**方法二、使用配置文件**

为wget使用代理，可以直接修改/etc/wgetrc，也可以在主文件夹下新建.wgetrc，并编辑相应内容，本文采用后者。

将/etc/wgetrc中与proxy有关的几行复制到~/.wgetrc，并做如下修改：

```
#You can set the default proxies for Wget to use for http, https, and ftp.
# They will override the value in the environment.
https_proxy = http://127.0.0.1:8087/
http_proxy = http://127.0.0.1:8087/
ftp_proxy = http://127.0.0.1:8087/

# If you do not want to use proxy at all, set this to off.
use_proxy = on/off
```

 这里 use_proxy = on 开启了代理，如果不想使用代理，每次都修改此文件未免麻烦，我们可以在命令中使用-Y参数来临时设置：

```
-Y, --proxy=on/off           打开或关闭代理
```

**方法三、使用-e参数**

wget本身没有专门设置代理的命令行参数，但是有一个"-e"参数，可以在命令行上指定一个原本出现在".wgetrc"中的设置。于是可以变相在命令行上指定代理：

```
-e, --execute=COMMAND   执行`.wgetrc'格式的命令
```

例如：

```
wget -c -r -np -k -L -p -e "http_proxy=http://127.0.0.1:8087" http://www.subversion.org.cn/svnbook/1.4/
```

 这种方式对于使用一个临时代理尤为方便。

**注:** 如果是https，则参数为：-e "**https_proxy**=http://127.0.0.1:8087"

使用https时如果想要忽略服务器端证书的校验，可以使用 -k 参数。
