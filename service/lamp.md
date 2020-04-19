<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-13 23:39:32
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-04-19 10:59:38
 -->
## Linux环境下LAMP环境yum安装


### 替换yum源

- 使用remi的源来安装php7.3，首先添加源：

  ```bash
  yum install epel-release
  rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
  ```

- [添加MariaDByum源](https://downloads.mariadb.org/mariadb/repositories)

  ```bash
  # MariaDB 10.4 CentOS repository list - created 2019-08-13 15:54 UTC
  # http://downloads.mariadb.org/mariadb/repositories/
  [mariadb]
  name = MariaDB
  baseurl = http://yum.mariadb.org/10.4/centos7-amd64
  gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
  gpgcheck=1
  ```

  [替换USTC源：](https://mirrors.ustc.edu.cn/help/mariadb.html)

  ```bash
  sudo sed -i 's#yum\.mariadb\.org#mirrors.ustc.edu.cn/mariadb/yum#' /etc/yum.repos.d/mariadb
  # 建议使用 HTTPS
  sudo sed -i 's#http://mirrors\.ustc\.edu\.cn#https://mirrors.ustc.edu.cn#g' /etc/yum.repos.d/mariadb
  ```

### 安装Apache

```bash
yum install -y httpd httpd-devel
```
### 安装MariaDB

```bash
sudo yum install MariaDB-server MariaDB-client
```

### 安装php模块：

```bash
yum --enablerepo=remi install php73-php php73-php-pear php73-php-bcmath \
php73-php-pecl-jsond-devel php73-php-mysqlnd php73-php-gd php73-php-common \
php73-php-fpm php73-php-intl php73-php-cli php73-php php73-php-xml \
php73-php-opcache php73-php-pecl-apcu php73-php-pdo php73-php-gmp \
php73-php-process php73-php-pecl-imagick php73-php-devel php73-php-mbstring \
php73-php-zip php73-php-ldap php73-php-imap php73-php-pecl-mcrypt
```

### 运行版本
运行并查看版本， 重启命令， 添加自动启动，链接php文件
```bash
php73 -v
# ln -s /opt/remi/php73/root/usr/bin/php /usr/bin/php    # 可不用链接
```

### 修改配置文件:

- apache:
  ```bash
  vim /etc/httpd/conf/httpd.conf

  # 找到 AddType application/x-gzip .gz .tgz (大概在284行) 添加如下：
  AddType application/x-httpd-php .php .phtml
  ```


- 相关配置文件：
  ```bash
  # The current PHP memory limit is below the recommended value of 512MB.
  vi /etc/opt/remi/php73/php.ini
  memory_limit = 512M
  ```

### 启动服务

```bash
 systemctl restart httpd.service mariadb.service    # php73-php-fpm.service
```

### 卸载软件
```bash
yum remove php73-php*
```


##连接 nginx 配置
  - 修改PHP文件
    ```conf
    # vim /etc/opt/remi/php73/php-fpm.d/www.conf

    # 修改：

    # 因为是通过 nfs 共享配置文件与 html，所以需要 用户名/用户组、UID/GID 保持一致，日常配置则不需要。
    user = apache
    group = apache

    # 修改监听端口：若上层有多个代理 nginx/apache 则填写 0.0.0.0，否则填写本机地址或回环网卡地址。
    listen = 0.0.0.0:9000

    # 取消 listen.owner 注释，因为远程 nginx/apache 会通过 9000 端口访问 PHP 服务器，而此时 PHP 服务器没有那个用户，所以 nginx 将以 nobody 用户访问。
    listen.owner = nobody                                                                                                                                           listen.group = nobody                                                                                                                                           listen.mode = 0660

    # 修改允许访问的客户端：多个主机用逗号分隔，注意不要填写自己的地址，不然远程地址无法访问。
    listen.allowed_clients = 192.168.0.95,192.168.0.88,192.168.0.33

    # 其他保持默认即可
    ```
    >重启php： `bash systemctl restart php73-php-fpm.service`

  - 修改 nginx 配置文件
    ```conf
    # vim /etc/nginx/nginx.conf

    # 修改运行用户：
    user nginx;

    # 注释 server 块内容，在 conf.d 目录中新建文件。(可扩展)
    #     server {
    #         listen       80 default_server;
    #         listen       [::]:80 default_server;
    #         server_name  _;
    #         root         /usr/share/nginx/html;
    #
    #         # Load configuration files for the default server block.
    #         include /etc/nginx/default.d/*.conf;
    #
    #         location / {
    #         }
    #
    #         error_page 404 /404.html;
    #             location = /40x.html {
    #         }
    #
    #         error_page 500 502 503 504 /50x.html;
    #             location = /50x.html {
    #         }
    #     }

    # vim /etc/nginx/conf.d/front.conf
    # 添加以下内容块：
    server {
      listen       80;
      server_name  _;
      access_log /var/log/nginx/php.access.log main;
      location / {
        root  /var/www/html;
          index index.php index.html index.htm;
          }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
          root  /usr/share/nginx/html;
          }
        location ~ \.php$ {
            root           /var/www/html;
            fastcgi_pass   fpm;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
            include        fastcgi_params;
          }
      }

    # vim /etc/nginx/fastcgi_params
    # 不知道会不会与 server 内的 fastcgi_garam 冲突；
    fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;

    # vim /etc/nginx/conf.d/upstream.conf
    # 添加
    upstream fpm {
      ip_hash;                      # 负载模式
      server 192.168.0.120:9000;    # PHP 服务器
      server 192.168.0.64:9000;
      server 192.168.0.135:9000;
      }
    ```
    >重启 nginx： `bash systemctl restart nginx`

