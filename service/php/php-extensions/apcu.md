## apcu
好老的鬼东西..
https://www.cnblogs.com/breg/p/3509010.html
https://blog.csdn.net/re_think/article/details/4412249
https://www.cnblogs.com/lchb/articles/3270763.html

### install
```shell
# install
wget https://pecl.php.net/get/apcu-5.1.21.tgz --no-check-certificate
tar -zxvf  apcu-5.1.21.tgz
cd apcu-5.1.21
/usr/local/php/bin/phpize ./configure --with-php-config=/usr/local/php/bin/php-config
./configure --with-php-config=/usr/local/php/bin/php-config
make
sudo make install
```

### config
```shell
extension=apcu.so
#zend_extension=xdebug.so
[apcu]
apc.enabled=1
apc.shm_size=1024M
apc.ttl=10800
apc.user_ttl=7200
apc.gc_ttl=3600
apc.slam_defense=1
apc.enable_cli=1
apc.serializer=php
apc.file_update_protection=2
apc.cache_by_default=1
apc.stat=1
apc.mmap_file_mask=/tmp/apc.XXXXXX
```

apcu 在PHP.ini中的配置(windows)
extension=php_apcu.dll
apc.enabled=1      ;apc.enabled: 启用或禁用APCu扩展。默认值为1，表示启用。
apc.shm_size=1024M ;apc.shm_size: 设置APCu的共享内存大小。这个选项设置得越大，可用于缓存的空间就越大。但是，设置得过大可能会浪费内存。
apc.ttl=10800      ;apc.ttl: 设置缓存的全局默认生存时间（TTL）。
apc.user_ttl=7200  ;apc.user_ttl: 设置用户缓存条目的默认生存时间。
apc.gc_ttl=3600    ;apc.gc_ttl: 设置垃圾收集器的默认生存时间。这个设置可以帮助你管理已经过期但是还没有被清理的缓存条目。
apc.slam_defense=1 ;开启slam defense防止同一个缓存项被多个请求同时创建
apc.enable_cli=1   ;允许在CLI模式下使用APCu

apc.serializer=php ;设置序列化器。默认值为php，表示使用PHP的序列化器。如果你使用的是PHP 7.0.6或更高版本，可以设置为igbinary，这样可以提高性能。
apc.file_update_protection=2 ;设置文件更新保护。默认值为2，表示在2秒内，文件的修改时间不会被检查。这个选项可以提高性能。
apc.cache_by_default=1 ;apc.cache_by_default: 设置是否缓存文件。默认值为1，表示缓存。如果你不想缓存文件，可以设置为0。
apc.stat=1 ;apc.stat: 设置是否检查文件的修改时间。默认值为1，表示检查。如果你不想检查文件的修改时间，可以设置为0。
apc.mmap_file_mask=/tmp/apc.XXXXXX ;apc.mmap_file_mask: 设置共享内存文件的路径和名称。默认值为/tmp/apc.XXXXXX，表示在/tmp目录下创建一个随机的文件。如果你想自定义共享内存文件的路径和名称，可以修改这个选项。
apc.preload_path= ;apc.preload_path: 设置预加载的文件。这个选项可以用来预加载一些文件，这样可以提高性能。如果你想预加载一些文件，可以在这里设置文件的路径和名称，多个文件之间用逗号分隔。
apc.num_files_hint=10000 ;apc.num_files_hint: 设置预加载的文件数量。默认值为10000，表示预加载10000个文件。如果你想预加载更多的文件，可以修改这个选项。
apc.user_entries_hint=10000 ;apc.user_entries_hint: 设置用户缓存条目的数量。默认值为10000，表示用户缓存10000个条目。如果你想缓存更多的条目，可以修改这个选项。
apc.gc_ttl=3600 ;apc.gc_ttl: 设置垃圾收集器的默认生存时间。默认值为3600，表示垃圾收集器的默认生存时间为3600秒。如果你想修改垃圾收集器的默认生存时间，可以修改这个选项。
apc.cache_by_default=1 ;apc.cache_by_default: 设置是否缓存文件。默认值为1，表示缓存。如果你不想缓存文件，可以设置为0。
apc.filters= ;apc.filters: 设置缓存文件的过滤器。这个选项可以用来过滤一些文件，这样可以提高性能。如果你想过滤一些文件，可以在这里设置文件的路径和名称，多个文件之间用逗号分隔。

### monitor
APC源包含一个php脚本，该脚本对于监控和调优性能的缓存是很有用的。
1. 下载APC监控文件：http://pecl.php.net/package/apc
2. 压缩包中的apc.php文件显示APC监控信息。
3. 运行这个文件，你会看到一个图形显示你的缓存一些统计数据。
4. 调优缓存，查看General Cache Information and Detailed Memory Usage and Fragmentation sections(总体缓存信息和详细的内存使用以及碎片部分)。
5. 监视Cache Full Count和碎片百分比，如果Cache Full Count大于0，表示缓存已满并且频繁读写，因为没有足够的内存被分配。增加apc.shm_size可解决问题。
6. 碎片百分比应该是0%，但是随着内存频繁的读写，其值会上涨。
7. 使用方法：直接访问 clement.com/apc.php
