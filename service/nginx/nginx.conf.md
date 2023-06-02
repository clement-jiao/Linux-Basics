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

    proxy_buffering on;
    proxy_hide_header X-Powered-By;
    proxy_hide_header Server;
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_cache_path /usr/local/nginx/cache/ levels=1:2 keys_zone=imgcache:512m inactive=1d max_size=10g;

    fastcgi_buffer_size 128k;
    fastcgi_buffers 4 128k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 256k;
    fastcgi_connect_timeout 600;
    fastcgi_send_timeout 600;
    fastcgi_read_timeout 600;
    client_header_buffer_size 51200k;
    client_max_body_size 100m;
    client_body_buffer_size 51200k;

    large_client_header_buffers 7 51200k;
    proxy_busy_buffers_size 256k;
    proxy_connect_timeout       600;
    proxy_send_timeout          600;
    proxy_read_timeout          600;
    send_timeout                600;

    # log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                   '$status $body_bytes_sent "$http_referer" '
    #                   '"$http_user_agent" "$http_x_forwarded_for"';
    # access_log  logs/access.log  main;

    # 兼容 es 日志采集: 注意 nginx 版本 1.15+
    log_format json escape=json '{ "time_local": "$time_iso8601", '
                    '"x_forwarded": "$http_x_forwarded_for", '
                    '"remote_addr": "$remote_addr", '
                    '"host": "$host", '
                    '"request_method": "$request_method", '
                    '"status": $status, '
                    '"request_uri": "$request_uri", '
                    '"request_body": "$request_body", '
                    '"referer": "$http_referer", '
                    '"bytes": $body_bytes_sent, '
                    '"agent": "$http_user_agent", '
                    '"up_addr": "$upstream_addr",'
                    '"up_host": "$upstream_http_host", '
                    '"upstream_time": "$upstream_response_time", '
                    '"request_time": "$request_time" }';

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


# 四层转发
stream {
    upstream backend {
        hash $remote_addr consistent;
        #server backend1.example.com:12345 weight=5;
        server 127.0.0.1:12345 max_fails=3 fail_timeout=30s;
        #server unix:/tmp/backend3;
    }

    server {
        listen 12345;
        proxy_connect_timeout 1s;
        proxy_timeout 3s;
        proxy_pass backend;
    }
}
```

> https://www.cnblogs.com/hovin/p/13182478.html
> https://www.cnblogs.com/wyt007/p/11425197.html # keepalived + nginx
