<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-13 23:42:45
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-14 00:12:16
 -->
#CentOS编译安装Nginx

```bash
#!/bin/sh
# Description: 安装nginx-1.12.1

SOFTWARE_DIR='/root/'

# ERROR Output
error_echo(){
    printf "\033[31m $* \033[0m\n"
}

# 安装nginx依赖包
nginx_package_install(){
    cd ${SOFTWARE_DIR} && tar zxf zlib-1.2.11.tar.gz -C /usr/src/
    cd ${SOFTWARE_DIR} && tar zxf pcre-8.40.tar.gz -C /usr/src/
    cd ${SOFTWARE_DIR} && tar zxf openssl-1.0.2.tar.gz -C /usr/src/
}

# 创建www用户
www_user_create(){
    groupadd www
    useradd -s /sbin/nologin -M -g www www
    mkdir -p /data/web/
}

# 安装nginx
nginx_install(){
    cd ${SOFTWARE_DIR} && tar zxf nginx-1.12.1.tar.gz -C /usr/src/ && cd /usr/src/nginx-1.12.1/
    ./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_v2_module --with-http_ssl_module --with-http_sub_module --with-http_realip_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_stub_status_module --with-zlib=/usr/src/zlib-1.2.11/ --with-pcre=/usr/src/pcre-8.40/ --with-openssl=/usr/src/openssl-1.0.2/ --pid-path=/usr/local/nginx/nginx.pid
    make && make install
}

# 配置nginx
nginx_config(){
    cd ${SOFTWARE_DIR}
    mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
    \cp -r nginx.conf /usr/local/nginx/conf/ && dos2unix /usr/local/nginx/conf/nginx.conf && ln -sf /usr/local/nginx/conf/nginx.conf /etc/nginx.conf
    rm -rf /usr/local/nginx/logs/ && mkdir -p /data/wwwlogs/ && ln -sf /data/wwwlogs /usr/local/nginx/logs
    mkdir -p /usr/local/nginx/conf/vhost/
    ln -sf /usr/local/nginx/sbin/nginx /usr/bin/
}

# 配置nginx启动脚本
nginx_init(){
    \cp -r nginx.init /etc/init.d/nginx && dos2unix /etc/init.d/nginx
    chmod a+x /etc/init.d/nginx
    chkconfig --add nginx && chkconfig --level 2345 nginx on
}

main(){
    nginx_package_install;
    www_user_create;
    nginx_install;
    nginx_config;
    nginx_init;
    /usr/bin/nginx -t
    if [ $? -eq 0 ]; then
        /etc/init.d/nginx start
        echo "nginx install successfully !!!"
    else
        error_echo "nginx install failed !!!"
    fi
}

main

```
