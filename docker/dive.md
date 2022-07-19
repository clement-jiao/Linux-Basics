## dive：按层分析docker镜像的工具

#### 使用
```bash
# 检查
dive <your-image-tag>

# 构建镜像
dive build -t <some-tag> .
```

#### 基本功能
按层分解显示的ocker图像内容当您在左侧选择一个图层时，将显示该图层的内容结合右边的所有先前图层。 此外，你可以充分探索带箭头键的文件树。现实每层的变化文件树显示已更改，已修改，添加或删除的文件。可以调整此值以显示特定图层的更改，或聚合更改到此层。估计image效率左下方窗格显示基本图层信息和实验指标猜猜您的图片包含多少浪费的空间。 这可能来自重复跨层文件，跨层移动文件或不完全删除文件。提供了百分比“得分”和总浪费的文件空间。快速构建/分析周期您可以构建Docker镜像并使用一个命令立即进行分析:dive build -t some-tag .您只需要使用相同的dive build替换docker build命令

#### 安装
**Ubuntu/Debian**
```bash
wget https://github.com/wagoodman/dive/releases/download/v0.4.1/dive_0.4.1_linux_amd64.deb
sudo apt install ./dive_0.4.1_linux_amd64.deb
```

**RHEL/Centos**

```bash
curl -OL https://github.com/wagoodman/dive/releases/download/v0.4.1/dive_0.4.1_linux_amd64.rpm
rpm -i dive_0.4.1_linux_amd64.rpm
```

**Arch Linux** 在Arch User Repository（AUR）中以dive的形式提供。
```bash
yay -S dive
```
以上示例假定[yay]（https://aur.archlinux.org/packages/yay/）作为安装AUR包的工具。

**Mac**
```bash
brew tap wagoodman/dive
brew install dive
```
或者从发布页下载最新的 Darwin 版本.

**Go tools**
```bash
# Note: 以这种方式安装，您将无法在运行时看到正确的版本 dive -v.
go get github.com/wagoodman/dive
```
**Docker**
```bash
docker pull wagoodman/dive

# or
docker pull quay.io/wagoodman/dive

# 运行时，您需要包含docker客户端二进制文件和套接字文件：
docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    wagoodman/dive:latest <dive arguments...>

# 适用于Windows的Docker（显示PowerShell兼容的换行符;折叠为一行以实现命令提示符兼容性）
docker run --rm -it \
    `-v /var/run/docker.sock:/var/run/docker.sock ` \
    wagoodman/dive:latest <dive arguments...>

# Note: 根据您在本地运行的docker版本，您可能需要将docker API版本指定为环境变量：
DOCKER_API_VERSION=1.37 dive ...

# or if you are running with a docker image:
docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e DOCKER_API_VERSION=1.37 \
    wagoodman/dive:latest <dive arguments...>
```


### 快捷键参考以下文档


#### 参考资料
**GitHub：**： https://github.com/wagoodman/dive
**译：** https://www.freebuf.com/sectool/191596.html
**image 优化：** https://mp.weixin.qq.com/s/nbl_sBC3fjRfBrzTq7u9SA