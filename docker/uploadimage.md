## 上传镜像至私有仓库
要上传镜像到私有仓库，需要在镜像的 tag 上加入仓库地址：
`docker tag express-app 111.111.111.111:5000/express-app:v1`

命名空间型tag： jiaoguofeng
`docker tag express-app 111.111.111.111:5000/jiaoguofeng/express-app:v1`
> 注意仓库地址没有加协议部分，docker 默认的安全策略需要仓库是支持 https 的，如果服务器只能使用 http 传输，那么直接上传会失败，需要在 docker 客户端的配置文件中进行声明。

### centos
在 /etc/docker/daemon.json 文件中写入：
```json
{
  "registry-mirror": [
    "https://registry.docker-cn.com"
  ],
  "insecure-registries": [
    "[私有仓库 ip:port]"
  ]
}
```
然后重启 docker
```bash
systemctl daemon-reload 
systemctl restart docker
```

### 推送镜像
打完 tag 后使用 push 命令推送即可：
`docker push 111.111.111.111:5000/jiaoguofeng/express-app:v1`

### 拉取镜像
使用 pull 命令即可

`docker pull 111.111.111.111:5000/jiaoguofeng/express-app:v1`

### 推送失败
如果出现 Retrying in 5 seconds 然后上传失败的问题。可以首先在服务器上使用 logs 命令查看日志：
`docker logs -f docker-registry`

如果出现 filesystem: mkdir /var/lib/registry/docker: permission denied，可能是 一个 selinux 问题，需要在服务器上对挂载目录进行处理：
`chcon -Rt svirt_sandbox_file_t /root/docker/registry/`