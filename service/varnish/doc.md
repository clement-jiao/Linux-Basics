## varnish

## doc
变量
https://varnish-cache.org/docs/trunk/reference/vcl-var.html

日志
https://blog.csdn.net/wos1002/article/details/56483301
`varnishncsa -bc -F '"%{Varnish:side}i" %h %l %u %t "%r" %s %b "%{Referer}i" "%{User-agent}i"'`
### packagecloud
https://packagecloud.io/varnishcache/varnish73/packages/el/7/varnish-7.3.0-1.el7.x86_64.rpm?distro_version_id=140

### repo
```bash
vim /etc/yum.repos.d/varnishcache_varnish73.repo

[varnishcache_varnish73]
name=varnishcache_varnish73
baseurl=https://packagecloud.io/varnishcache/varnish73/el/7/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/varnishcache/varnish73/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[varnishcache_varnish73-source]
name=varnishcache_varnish73-source
baseurl=https://packagecloud.io/varnishcache/varnish73/el/7/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/varnishcache/varnish73/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

# curl -s https://packagecloud.io/install/repositories/varnishcache/varnish73/script.rpm.sh | sudo bash
```
