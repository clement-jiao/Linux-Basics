<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-04-30 23:08:34
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-04-30 23:09:58
 -->
当我pip install scrapy过程中发现Twisted报错。

于是我尝试pip install twisted单独安装Twisted, 依然是报错。

后来发现原来是twisted和高版本的python有兼容性问题。

那么怎么结局呢？

我发现了Python扩展包的非官方Windows二进制文件里有：

Twisted, an event-driven networking engine.
```
Twisted‑17.9.0‑cp27‑cp27m‑win32.whl
Twisted‑17.9.0‑cp27‑cp27m‑win_amd64.whl
Twisted‑17.9.0‑cp34‑cp34m‑win32.whl
Twisted‑17.9.0‑cp34‑cp34m‑win_amd64.whl
Twisted‑17.9.0‑cp35‑cp35m‑win32.whl
Twisted‑17.9.0‑cp35‑cp35m‑win_amd64.whl
Twisted‑17.9.0‑cp36‑cp36m‑win32.whl
Twisted‑17.9.0‑cp36‑cp36m‑win_amd64.whl
```
赶紧的，到 https://www.lfd.uci.edu/~gohlke/pythonlibs/ 下载 Twisted‑17.9.0‑cp36‑cp36m‑win_amd64.whl

执行：

pip install  Twisted‑17.9.0‑cp36‑cp36m‑win_amd64.whl
依然错误了。报错显示说，我的平台不能运行这个。

于是下载另一个版本Twisted‑17.9.0‑cp36‑cp36m‑win32.whl

执行：
pip install  Twisted‑17.9.0‑cp36‑cp36m‑win32.whl

成功!
如果在运行的过程中，需要pywin32, 可以使用下面命令安装：`pip install pypiwin32`
