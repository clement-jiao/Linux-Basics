##Linux环境下LNMP环境yum安 b装


###安装 remi源

使用remi的源来安装，首先添加源：

```bash
yum install epel-release
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
```


###安装php模块：

```bash
yum --enablerepo=remi install php73-php php73-php-pear php73-php-bcmath php73-php-pecl-jsond-devel php73-php-mysqlnd php73-php-gd php73-php-common php73-php-fpm php73-php-intl php73-php-cli php73-php php73-php-xml php73-php-opcache php73-php-pecl-apcu php73-php-pdo php73-php-gmp php73-php-process php73-php-pecl-imagick php73-php-devel php73-php-mbstring php73-php-zip php73-php-ldap php73-php-imap php73-php-pecl-mcrypt
```

###运行版本
运行并查看版本， 重启命令， 添加自动启动，链接php文件
```bash
php73 -v
systemctl restart php73-php-fpm
systemctl enable  php73-php-fpm
ln -s /opt/remi/php73/root/usr/bin/php /usr/bin/php
```

###配置文件路径:

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

###卸载软件
```bash
yum remove php73-php*
```
