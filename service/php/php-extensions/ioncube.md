## ioncube：加密扩展
### 前提条件：
1、通过下面的地址下载loader-wizard：http://www.ioncube.com/loader-wizard/loader-wizard.zip

### 一、添加 nginx 配置
```bash
server {
    listen 80;
    # 添加 hosts 解析
    server_name ioncube.ibaiqiu.com;
    root /home/wwwroot/ioncube;
 
    location / {
        index loader-wizard.php;
        if (!-e $request_filename) {
            rewrite ^/(.*) /index.php?$1 last;
        }
    }
 
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

#### Apache 配置
```bash

<VirtualHost 172.16.33.237>
    ServerAdmin webmaster@example.com
    DocumentRoot "/home/wwwroot/ioncube/"
    ServerName ioncube.ibaiqiu.com
 
    ErrorLog "/home/wwwlogs/IP-error_log"
    CustomLog "/home/wwwlogs/IP-access_log" combined
    <Directory "/home/wwwroot/ioncube/">
        SetOutputFilter DEFLATE
        Options FollowSymLinks
        AllowOverride All
        Order allow,deny
        Allow from all
        DirectoryIndex index.html index.php
    </Directory>
</VirtualHost>
```

### 二、重启 nginx，拷贝扩展
1、访问：http://ioncube.ibaiqiu.com/loader-wizard.php；
2、注意勾选（选项三）：Local install（忘记勾选后重新安装无效，暂未找到解决方案）；
3、下载 tar.gz/zip 文件至服务器，拷贝 ioncube_loader_lin_7.xx.so 文件到 extensions/no-debug-non-zts-20160303/，为 so 文件添加 755 权限；
4、修改 php.ini ，将扩展添加进配置文件 ( 页面有 php.ini 示例可以直接复制 ): `zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20160303//ioncube_loader_lin_7.1.so` ;

### 三、重启php
service php-fpm restart

### 四、验证
```bash
[root@localhost root]$ php -m
...
[Zend Modules]
the ionCube PHP Loader + ionCube24
 
 
[root@localhost root]$ php -v
PHP 7.1.33 (cli) (built: Oct 31 2022 14:56:06) ( NTS )
Copyright (c) 1997-2018 The PHP Group
Zend Engine v3.1.0, Copyright (c) 1998-2018 Zend Technologies
    with the ionCube PHP Loader + ionCube24 v12.0.2, Copyright (c) 2002-2022, by ionCube Ltd.
```

### 五、清理相关配置，防止误访问
rm -rf ./ioncube
rm -rf ioncube.conf