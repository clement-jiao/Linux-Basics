# docker push registry-harbor.clement.com/clement/php-fpm-nginx:php81-v1.1.1
# docker build . -t registry-harbor.clement.com/clement/php-fpm-nginx:php81-v1.1.1
# v1.1.1 - php8.1.7-fpm-alpine3.16 + nginx
# php81-v1.1.1 - php8.1.7-fpm-alpine3.16 + nginx

# FROM php:8.1.7-apache-buster
FROM php:8.1.7-fpm-alpine3.16 
ENV http_proxy http://ip:port

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

COPY php.ini /usr/local/etc/php/conf.d/php.ini
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY www.conf /usr/local/etc/php-fpm.d/www.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY init.sh /usr/local/bin/init.sh
COPY nginx.conf /etc/nginx/nginx.conf

RUN chmod +x /usr/bin/init.sh
RUN chmod +x /usr/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions redis mysqli intl sockets shmop sysvsem \
        pdo pdo_mysql ctype iconv zip bcmath soap libxml shmop sockets gettext mcrypt pcntl xmlrpc xsl \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update && apk add --no-cache -U nginx \
    && rm -rf /var/cache/apk/* && rm -rf /tmp/*

ENV http_proxy ""

WORKDIR /var/www/html

ENTRYPOINT /usr/bin/entrypoint.sh

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