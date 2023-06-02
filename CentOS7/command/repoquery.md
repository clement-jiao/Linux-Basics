## 查 *.so 文件出处

```bash
# 其他用法以后在查

[root@loclhost root]$ repoquery --nvr --whatprovides libXss.so.1
[root@loclhost root]$ libXScrnSaver-1.2.2-6.1.el7
[root@loclhost root]$ yum install -y libXScrnSaver-1.2.2-6.1.el7
```


https://newsn.net/say/electron-libxss.html