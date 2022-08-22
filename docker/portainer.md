## Docker管理面板Portainer

### 可替换产品
Kitematic 感觉一般

官网 https://kitematic.com
github地址 https://github.com/docker/kitematic

### 官方正版
github
https://github.com/portainer/portainer

dockerhub
https://hub.docker.com/r/portainer/portainer-ce

部署文档
https://docs.portainer.io/start/install/server/docker/linux

### 汉化版
```yaml
version: '3'
services:
  portainer:
    image: hub-mirror.c.163.com/6053537/portainer-ce
    container_name: portainer
    restart: always
    volumes:
      - /etc/localtime:/etc/localtime
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/portainer:/data
    ports:
    # 8000 不知道干啥用的，9000 是 web 端口。
      - 8000:8000
      - 8080:9000
```
### 中文汉化版
https://hub.docker.com/r/6053537/portainer-ce

参考资料
https://imnks.com/3406.html