### mitmproxy

需要在Debian中升级 Python3.7 以上版本，安装部分官方文档说的很详细，唯一没提到的是pipx的其他用法，到时候有需要再看吧。

启动部分可以看以下选项：

```bash
nohup mitmweb --web-host=[本机地址] --web-port=8080 --listen-host=0.0.0.0 --listen-port=8081 --set block_global=false --proxyauth="clement:clement123" 2>&1 >> /root/mitmproxy.log &
```

注意:

```bash
# 要设置为任意地址可代理时需要
--set block_global=false
```

认证相关：

```bash
# 目前有三种 auth，没有对 web 页面的 auth ：
# 1. proxyauth：proxy prot：8081 连接时认证
# 2. stickyauth：Set sticky auth filter. Matched against requests.
# 3. upstream_auth
# 普通用户名密码认证：
--proxyauth="clement:clement123"
# ldap 认证：唯一不足的是只能使用 ldap 默认端口，没找到可以在哪设置端口的地方或选项
--proxyauth="ldap:1.1.1.1:cn=admin,dc=clement,dc=com:clement:ou=user,dc=clement,dc=com"
```

证书：

```bash
# 注意下载是只能通过直连的方式进行下载，如通过其他代理再连接会提示没有权限
http://mitm.it
```

结合 Python 使用：[MitmProxy 使用教程 – 结合Python-Python](https://pythondict.com/scrapy/mitmproxy/)

官方文档：[Installation (mitmproxy.org)](https://docs.mitmproxy.org/stable/overview-installation/)

中文文档：[前言 · 抓包代理利器：mitmproxy (crifan.github.io)](https://crifan.github.io/crawler_proxy_tool_mimproxy/website/)

docker：[在docker中部署mitmproxy并执行脚本](https://blog.csdn.net/qq_33430083/article/details/103482326)

教程：[Mitmproxy教程 - zha0gongz1)](https://www.cnblogs.com/H4ck3R-XiX/p/12624072.html)

