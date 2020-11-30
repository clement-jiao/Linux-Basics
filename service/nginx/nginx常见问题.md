<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-11-27 11:03:07
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-11-27 11:54:07
-->

### nginx常见问题总结

##### Nginx 禁止未匹配域名访问
```conf
server {
    listen       80 default_server;  # 这里是重点 #
    #server_name  localhost;
    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        return 404;              # 还有这里, 返回444也可以 #
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```
##### Nginx 指定别名目录
```conf
location ^~ /zgjh {
    add_header Cache-Control no-store;  # 禁止缓存
    # root   /workspace;
    # index  index.html index.htm;
    alias /workspace/axure/zgjh/latest/;
    autoindex on;
    autoindex_localtime on;
    autoindex_exact_size off;
}
```
