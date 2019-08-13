<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-13 23:39:32
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-14 01:25:31
 -->
##Linux环境下LNMP环境yum安装


###替换yum源

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

###安装Apache

```bash
yum install -y httpd
```
###安装MariaDB

```bash
sudo yum install MariaDB-server MariaDB-client
```

###安装php模块：

```bash
yum --enablerepo=remi install php73-php php73-php-pear php73-php-bcmath php73-php-pecl-jsond-devel php73-php-mysqlnd php73-php-gd php73-php-common php73-php-fpm php73-php-intl php73-php-cli php73-php php73-php-xml php73-php-opcache php73-php-pecl-apcu php73-php-pdo php73-php-gmp php73-php-process php73-php-pecl-imagick php73-php-devel php73-php-mbstring php73-php-zip php73-php-ldap php73-php-imap php73-php-pecl-mcrypt
```

###运行版本
运行并查看版本， 重启命令， 添加自动启动，链接php文件
```bash
php73 -v
# ln -s /opt/remi/php73/root/usr/bin/php /usr/bin/php    # 可不用链接
```

###修改配置文件:

- apache:
  ```bash
  vim /etc/httpd/conf/httpd.conf

  # 找到 AddType application/x-gzip .gz .tgz (大概在284行) 添加如下：
  AddType application/x-httpd-php .php .phtml
  ```


- 路径：
  ```bash
  # The current PHP memory limit is below the recommended value of 512MB.
  vi /etc/opt/remi/php73/php.ini
  memory_limit = 512M
  #如果你运行的是nginx而不是apache，修改
  vi /etc/opt/remi/php73/php-fpm.d/www.conf
  user = apache
  group = apache
  # Replace the values with
  user = nginx
  group = nginx
  ```

###启动服务

```bash
 systemctl restart httpd.service mariadb.service php73-php-fpm.service
```

###卸载软件
```bash
yum remove php73-php*
```
