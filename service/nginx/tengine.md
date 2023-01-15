## tengine


```bash
./configure \
--prefix=/usr/local/tengine \
--group=www \
--user=www \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_gzip_static_module \
--with-pcre \
--with-http_realip_module \
--with-stream_ssl_module \
--with-http_v2_module \
--with-http_addition_module \
--with-http_sub_module \
--with-http_degradation_module \
--with-stream \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-jemalloc \
--add-module=/usr/local/src/nginx-sticky-module-1.26
```


### ptmalloc、tcmalloc与jemalloc对比分析
ptmalloc: glibc
tcmalloc: google perftools module
jemalloc: jemalloc module

https://blog.csdn.net/zzhongcy/article/details/40045803
https://www.cyningsun.com/07-07-2018/memory-allocator-contrasts.html