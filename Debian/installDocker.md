[toc]

## install and Use Docker on Debian 10



### 安装依赖

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 lsb-release software-properties-common wget vim

# 添加秘钥
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 设置 docker 镜像库
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装
 sudo apt-get update
 sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```



### 参考文档

[docker 官方文档]([Install Docker Engine on Debian | Docker Documentation](https://docs.docker.com/engine/install/debian/))