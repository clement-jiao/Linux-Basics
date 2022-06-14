<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-27 11:06:31
 * @LastEditors: clement-jiao
 * @LastEditTime: 2022-05-13 16:07:56
-->

### nginx.conf 配置
```conf
user  nginx;
worker_processes  2;
worker_rlimit_nofile 65535;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  10240;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    server_tokens   off;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;
    #gzip  on;
    client_max_body_size 100M;
    include /etc/nginx/conf.d/*.conf;
    #include /etc/nginx/nginx-badbot-blocker/*.conf;

    server_names_hash_bucket_size 64;
    server_names_hash_max_size 4096;
}
```

> https://www.cnblogs.com/hovin/p/13182478.html
