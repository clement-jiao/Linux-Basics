### dnf

centos7 下的 dnf 安装

```bash
yum -y update python*

yum -y install dnf-data dnf-plugins-core libdnf-devel libdnf python2-dnf-plugin-migrate dnf-automatic

echo 'export LC_ALL="en_US.UTF-8"' >> /etc/profile
echo 'export LANG="zh_CN.GBK"' >> /etc/profile
source /etc/profile
```


dnf swap centos-linux=repos centos-stream-repos
dnf distro-sync
