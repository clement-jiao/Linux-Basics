## opcache

opcache 解析
https://mp.weixin.qq.com/s/CXd-V99faSnXPzVbTwqawg

opcache 的一些配置
https://dudashuang.com/laravel-performance/

```conf
[Zend Opcache]
;zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20090626/opcache.so
opcache.enable=1 ;启用操作码缓存
opcache.enable_cli=1 ;仅针对CLI环境启用操作码缓存
opcache.memory_consumption=128 ;共享内存大小，单位MB
opcache.interned_strings_buffer=8 ;存储临时字符串的内存大小，单位MB
opcache.max_accelerated_files=4000 ;哈希表中可存储的脚本文件数量上限
;opcache.max_wasted_percentage=5 ;浪费内存的上限，以百分比计
;opcache.use_cwd=1;附加改脚本的工作目录,避免同名脚本冲突
opcache.validate_timestamps=1 ;每隔revalidate_freq 设定的秒数 检查脚本是否更新
opcache.revalidate_freq=60 ;
;opcache.revalidate_path=0 ;如果禁用此选项，在同一个 include_path 已存在的缓存文件会被重用
;opcache.save_comments=1 ;禁用后将也不会加载注释内容
opcache.fast_shutdown=1 ;一次释放全部请求变量的内存
opcache.enable_file_override=0 ; 如果启用，则在调用函数file_exists()， is_file() 以及 is_readable() 的时候， 都会检查操作码缓存
;opcache.optimization_level=0xffffffff ;控制优化级别的二进制位掩码。
;opcache.inherited_hack=1 ;PHP 5.3之前做的优化
;opcache.dups_fix=0 ;仅作为针对 “不可重定义类”错误的一种解决方案。
;opcache.blacklist_filename="" ;黑名单文件为文本文件，包含了不进行预编译优化的文件名
;opcache.max_file_size=0 ;以字节为单位的缓存的文件大小上限
;opcache.consistency_checks=0 ;如果是非 0 值，OPcache 将会每隔 N 次请求检查缓存校验和
opcache.force_restart_timeout=180 ; 如果缓存处于非激活状态，等待多少秒之后计划重启。
;opcache.error_log="" ;OPcache模块的错误日志文件
;opcache.log_verbosity_level=1 ;OPcache模块的日志级别。致命（0）错误（1) 警告（2）信息（3）调试（4）
;opcache.preferred_memory_model="" ;OPcache 首选的内存模块。可选值包括： mmap，shm, posix 以及 win32。
;opcache.protect_memory=0 ;保护共享内存，以避免执行脚本时发生非预期的写入。 仅用于内部调试。
;opcache.mmap_base=null ;在Windows 平台上共享内存段的基地址
```



### 关于 opcache 的漏洞？
https://chybeta.github.io/2017/05/13/利用PHP的OPcache机制getshell/

### OPcache 注意事项及调优
https://learnku.com/php/t/34638
https://tideways.com/profiler/blog/fine-tune-your-opcache-configuration-to-avoid-caching-suprises (英文)
