# FROM php:8.1.7-apache-buster
FROM php:8.1.7-fpm-alpine3.16 

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

COPY php.ini /usr/local/etc/php/conf.d/php.ini
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

RUN chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions redis mysqli intl sockets shmop sysvsem \
        pdo pdo_mysql ctype iconv zip bcmath soap libxml shmop sockets gettext mcrypt pcntl xmlrpc xsl \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update && apk add --no-cache -U nginx \
    && rm -rf /var/cache/apk/* && rm -rf /tmp/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/html


# 参考示例
RUN php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    mv composer.phar /usr/local/bin/composer && \
    rm -rf composer-setup.php && \
    apt-get update && \
    apt-get install -y autoconf make gcc musl-dev g++ zip unzip libicu-dev zlib1g-dev libzip-dev libxml2 libxml2-dev wget && \
    docker-php-ext-configure gd sockets shmop && \
    docker-php-ext-install pdo pdo_mysql ctype iconv zip bcmath soap libxml shmop sockets && \
    pecl install redis-5.3.2 && \
    # pecl install xdebug-2.9.7 && \
    docker-php-ext-enable redis mysqli intl sockets shmop sysvsem && \
    # php xdebug
    mkdir -p /usr/local/php/xdebug_profiler && \
    mkdir -p /usr/local/php/xdebug_trace && \
    mkdir -p /usr/local/php/xdebug && \
    touch /usr/local/php/xdebug/remote.log && \
    apt-get remove -y --purge autoconf make gcc musl-dev g++ zlib1g-dev && \
    rm -rf /var/cache/apt/* && rm -rf /tmp/*


curl -sSLf \
        -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions redis-5.3.2 mysqli intl sockets shmop sysvsem pdo pdo_mysql ctype iconv zip bcmath soap libxml shmop sockets gettext mcrypt pcntl xmlrpc xsl