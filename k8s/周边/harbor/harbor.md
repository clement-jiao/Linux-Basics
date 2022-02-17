[toc]

## harbor

[Harbor](https://goharbor.io/) 是 `VMware` 公司开源了企业级 `Registry` 项目, 其的目标是帮助用户迅速搭建一个企业级的 `Docker registry` 服务。

由于 Harbor 是基于 Docker Registry V2 版本，所以 docker 版本必须 `>=1.10.0` [docker-compose](https://docs.docker.com/compose/install/#prerequisites) `>=1.6.0`

Github: [goharbor/harbor](https://github.com/goharbor/harbor)，官方[预览示例](https://demo.goharbor.io/)

对硬件需求

> CPU  =>   最小 2CPU/4CPU(首选)
>         Mem =>  最小 4GB/8GB(首选)
>         Disk  =>   最小 40GB/160G(首选)

### 下载安装包

#### 安装 docker-compose

harbor 整体是通过 [docker-compose](https://docs.docker.com/compose/install/#prerequisites) 进行安装部署，所以必须下载 docker 及 docker-compose。

```bash
# 下载最新版 `Docker Compose`
sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 对二进制文件应用可执行权限：
sudo chmod +x /usr/local/bin/docker-compose

# 测试是否安装成功
docker-compose --version
# docker-compose version 1.22.0, build f46880fe
```

#### 下载安装包

可以从[发布页面](https://github.com/goharbor/harbor/releases)下载安装程序的二进制文件，选择在线或离线安装程序，使用tar命令解压缩包，天朝人民下面这种方式安装可能要翻墙，推荐这种方式，因为上面也不见得能下载下来。

```bash
# 当前版本是 2.2.1
wget https://github.com/goharbor/harbor/releases/download/v2.2.1/harbor-online-installer-v2.2.1.tgz
# 解压
tar zxf harbor-online-installer-v2.2.1.tgz && cd harbor/ && cp harbor.yml.tmpl harbor.yml
```

### 修改配置

进去 `vim harbor/harbor.yaml` 修改文件相关配置。(貌似 1.X 版本是cfg，到了2.X 改为yaml)

```yaml
# 注意需要修改的地方
hostname: registry-harbor.clemente.net
https:
  # https port for harbor, default is 443
  port: 443
  # The path of cert and key files for nginx
  # 证书是acme目录
  certificate: /root/.acme.sh/registry-harbor.clemente.net/fullchain.cer
  private_key: /root/.acme.sh/registry-harbor.clemente.net/registry-harbor.clemente.net.key

# 如果使用外部db则不需要注释这行
database:
# 都要填
external_database:
	harbor:
	notary_signer:
	notary_server:
external_redis:
	host: 172.0.24.46:6379
	# db_index 0 is for core, it's unchangeable
	# 官方警告：是真的不能改 harbor-core 的redis库
  registry_db_index: 11
  jobservice_db_index: 12
  chartmuseum_db_index: 13
  trivy_db_index: 15
  idle_timeout_seconds: 30
# 还有些代理啥的配置，现在没动可以以后再研究。
proxy:
# metric:
```

完成后直接  `./install.sh`

```bash
root@debian:~/harbor# ./install.sh -h

Note: Please set hostname and other necessary attributes in harbor.yml first. DO NOT use localhost or 127.0.0.1 for hostname, because Harbor needs to be accessed by external clients.
Please set --with-notary if needs enable Notary in Harbor, and set ui_url_protocol/ssl_cert/ssl_cert_key in harbor.yml bacause notary must run under https.
Please set --with-trivy if needs enable Trivy in Harbor             # 开启扫描器支持
Please set --with-chartmuseum if needs enable Chartmuseum in Harbor # 开启对helm支持
```

安装脚本会先执行 `prepare`， 再 `docker-compose down -v`  最后 `docker-compose up -d`

### 同步脚本

```bash
vim registrySync.sh

#!/bin/bash
# print the directory and file
# /usr/bin/cd /data/registry/v2.bakup/repositories/

for file in /root/harbor/repos/*
do
  if [ -d "$file" ]
  then
    # echo "$file is directory"
    registryName=$(basename $file)
    skopeo sync --src docker --dest docker registry.clemente.net:5000/$registryName registry-harbor.clemente.net/clemente
    # mkdir -p /root/registry/$registryName
    # echo $registryName
  elif [ -f "$file" ]
  then
    echo "$file is file"
  fi
done
#/usr/bin/skopeo login --get-login registry.clemente.net:5000
#/usr/bin/skopeo login --get-login harbor.clemente.net
```

#### return 403之类的问题

> 先尝试 docker login 会不会报错，如果没报错多半是系统不信任自签证书。


#### 添加 docker 对 80 仓库的支持 （非443为不信任）
```bash
root@harbor01:~/harbor$ vim /usr/lib/systemd/system/docker.service
# 将启动脚本
# ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
# 修改为
# ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --insecure-registry 172.16.31.1 --insecure-registry 172.16.31.2
root@debian:~/harbor# systemctl daemon-reload
root@debian:~/harbor# systemctl restart docker.service
```

### 手动签发证书

```bash
root@debian:~$ openssl req -x509 -new -nodes -key ./harbor-ca.key -subj "harbor.clemente.com"
root@debian:~$ openssl req -x509 -new -nodes -key ./harbor-ca.key -subj "/CN=harbor.clemente.com"  -days 3650 -out ./harbor-ca.crt
```



#### 参考资料

[skopeo install  (github.com) (centos/debian/mac 他都有)](https://github.com/containers/skopeo/blob/master/install.md)

[4 种方法将 Docker Registry 迁移至 Harbor (qq.com)](https://mp.weixin.qq.com/s/YGmhvTaYEt5L5xN7QxPQHQ)

[镜像搬运工 skopeo 初体验 | 木子 (k8s.li)](https://blog.k8s.li/skopeo.html)

[Docker入门教程 - Docker入门教程 (gitbook.io)(帮助很大)](https://hezhiqiang-book.gitbook.io/docker/)



### 安全证书脚本

> 感谢：杰哥大佬提供的脚本，拿来改一改就能用了

```bash
#!/bin/bash
# Usage: ./cert.sh [init|refresh]
# echo "15 16 * * * /var/docker-environment/base/cert.sh refresh" >> /var/spool/cron/root

name=$1
# SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)
SHELL_FOLDER=/data/secret/cert/
domainName=registry-harbor.clemente.net

if [ -z $name ]; then
  name=""
fi

# cd $SHELL_FOLDER

if [ $name == "init" ]; then
  echo "init acmesh.sh"
  curl  https://get.acme.sh | sh
  chmod a+x ~/.acme.sh/acme.sh
  # auto update
  ~/.acme.sh/acme.sh  --upgrade
  ~/.acme.sh/acme.sh  --issue -d $domainName --standalone --httpport 80 --force --server  letsencrypt
  elif [ $name == "refresh" ]; then
      echo "refresh domain cert"
      # rm -rf  /data/secret/cert/server.key
      # auth file to nginx-html
      # --force 注意是强制更新！使用的时候需要去掉，SHELL_FOLDER 指安装证书的路径。
      # 会自动加入定时任务，注意查看就好
      /usr/bin/docker stop nginx
      ~/.acme.sh/acme.sh  --installcert --issue -d $domainName \
                          --key-file $SHELL_FOLDER/server.key \
                          --fullchain-file $SHELL_FOLDER/server.crt \
                          --standalone --force
                          # --reloadcmd "/usr/bin/docker start nginx"
      chown -R 10000:10000 /data/secret/cert/
      /usr/bin/docker start nginx
  else
    echo "Doesn't support arg $name, please use ./cert.sh [init|refresh]"
fi
```

#### 参考资料

> 这玩意儿用着还是蛮方便的嘛，以后可以考虑多用用这个。既有http也有dns，还有port认证。再次感谢大佬

[说明 · acmesh-official/acme.sh Wiki (github.com)](https://github.com/acmesh-official/acme.sh/wiki/说明)









