[toc]

## install and Use Docker on Debian 10



### 安装依赖

```bash
apt update && apt install -y apt-transport-https ca-certificates curl gnupg2 lsb-release software-properties-common wget vim htop ncdu curl nethogs

# 添加秘钥
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 设置 docker 镜像库
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装
 sudo apt update
 sudo apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

```json
// /etc/dokcer/daemon.json
// mkdir /etc/docker
{
  "registry-mirrors" : [
    "http://registry.docker-cn.com",
    "http://docker.mirrors.ustc.edu.cn",
    "http://hub-mirror.c.163.com"
  ],
  "insecure-registries" : [
    "registry.docker-cn.com",
    "docker.mirrors.ustc.edu.cn"
  ],
  "debug" : true,
  "experimental" : true
}
```

### 参考文档

[docker 官方文档]([Install Docker Engine on Debian | Docker Documentation](https://docs.docker.com/engine/install/debian/))
