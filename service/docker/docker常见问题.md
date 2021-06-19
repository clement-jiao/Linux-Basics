<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-27 11:55:33
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-11-27 11:57:58
-->
## docker 常见问题总结

### docker-compose 安装失败

**docker-compose 安装失败 Cannot open self /usr/local/bin/docker-compose**

使用 docker compose 运行报错:
```bash
[deploy@iZbp1eelh6pez5j1wzv881Z :~]$ [1458] Cannot open self /usr/local/bin/docker-compose or archive /usr/local/bin/docker-compose.pkg

# 运行:
[deploy@iZbp1eelh6pez5j1wzv881Z :~]$ docker-compose --version
# 报错：
Cannot open self /usr/local/bin/docker-compose or archive /usr/local/bin/docker-compose.pkg
# 查找原因发现可能是由于网络原因下载的不完整？
# 换一种下载方式
[deploy@iZbp1eelh6pez5j1wzv881Z :~]$ wget https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m) -O /usr/local/bin/docker-compose
```



### 指定 http 型私有仓库

一般会报错：

```bash
docker pull 192.168.99.100:5000/image
Using default tag: latest
Error response from daemon: Get https://192.168.99.100:5000/v2/: http: server gave HTTP response to HTTPS client
```

在 `/etc/docker/daemon.json` 中加入

```bash
vim /etc/docker/daemon.json
{"insecure-registries":["192.168.99.100:5000"]}

# 重启 docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

[windows - Docker repository server gave HTTP response to HTTPS client - Stack Overflow](https://stackoverflow.com/questions/49674004/docker-repository-server-gave-http-response-to-https-client)





