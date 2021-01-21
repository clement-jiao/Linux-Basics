<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-27 11:55:33
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-11-27 11:57:58
-->
### docker 常见问题总结
##### docker-compose 安装失败 Cannot open self /usr/local/bin/docker-compose

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


