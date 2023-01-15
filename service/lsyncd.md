
## lsyncd
### building
```bash
yum install -y gcc gcc-c++ lua lua-devel cmake3 libxml2 libxml2-devel

mkdir /usr/local/lsyncd
cd lsyncd-2.3.1
cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local/lsyncd
```

out:
```bash
[root@WEB01 lsyncd-2.3.1]# mkdir /usr/local/lsyncd
[root@WEB01 lsyncd-2.3.1]# cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local/lsyncd
CMake Warning:
  No source or binary directory provided.  Both will be assumed to be the
  same as the current working directory, but note that this warning will
  become a fatal error in future CMake releases.


-- The C compiler identification is GNU 4.8.5
-- The CXX compiler identification is GNU 4.8.5
-- Check for working C compiler: /usr/bin/cc
-- Check for working C compiler: /usr/bin/cc - works
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Detecting C compile features
-- Detecting C compile features - done
-- Check for working CXX compiler: /usr/bin/c++
-- Check for working CXX compiler: /usr/bin/c++ - works
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Found Lua: /usr/lib64/liblua.so;/usr/lib64/libm.so (found version "..") 
-- Configuring done
-- Generating done
-- Build files have been written to: /usr/local/src/lsyncd-2.3.1
[root@WEB01 lsyncd-2.3.1]# make
Scanning dependencies of target prepare_tests
[ 10%] Built target prepare_tests
[ 20%] Generating defaults.out
Compiling built-in default configs
[ 30%] Generating runner.out
Compiling built-in runner
[ 40%] Generating runner.c
Generating built-in runner linkable
[ 50%] Generating defaults.c
Generating built-in default configs
Scanning dependencies of target lsyncd
[ 60%] Building C object CMakeFiles/lsyncd.dir/lsyncd.c.o
[ 70%] Building C object CMakeFiles/lsyncd.dir/runner.c.o
[ 80%] Building C object CMakeFiles/lsyncd.dir/defaults.c.o
[ 90%] Building C object CMakeFiles/lsyncd.dir/inotify.c.o
[100%] Linking C executable lsyncd
[100%] Built target lsyncd
[root@WEB01 lsyncd-2.3.1]# make install
[ 10%] Built target prepare_tests
[100%] Built target lsyncd
Install the project...
-- Install configuration: ""
-- Installing: /usr/local/lsyncd/bin/lsyncd
-- Installing: /man1/lsyncd.1
-- Installing: /usr/local/lsyncd/doc/examples
-- Installing: /usr/local/lsyncd/doc/examples/lalarm.lua
-- Installing: /usr/local/lsyncd/doc/examples/lbash.lua
-- Installing: /usr/local/lsyncd/doc/examples/lecho.lua
-- Installing: /usr/local/lsyncd/doc/examples/lftp.lua
-- Installing: /usr/local/lsyncd/doc/examples/lgforce.lua
-- Installing: /usr/local/lsyncd/doc/examples/limagemagic.lua
-- Installing: /usr/local/lsyncd/doc/examples/lpostcmd.lua
-- Installing: /usr/local/lsyncd/doc/examples/lrsync.lua
-- Installing: /usr/local/lsyncd/doc/examples/lrsyncssh-advanced.lua
-- Installing: /usr/local/lsyncd/doc/examples/lrsyncssh-tunnel.lua
-- Installing: /usr/local/lsyncd/doc/examples/lrsyncssh.lua
-- Installing: /usr/local/lsyncd/doc/examples/ls3.lua
-- Installing: /usr/local/lsyncd/doc/examples/lsayirc.lua
[root@WEB01 lsyncd-2.3.1]#
```


### config file
要求 rsync 版本大于 3.1，一般默认版 3.1.2。

```lua
settings {
    pidfile = "/var/run/syncd.pid",
    logfile = "/var/log/lsyncd.log",
    statusFile = "/var/run/lsyncd.status",
    inotifyMode = "CloseWrite or Modify",
    # rsyncssh 模式下必须=1
    maxProcesses = 2,
}
sync {
    default.rsync,
    source = "/home/wwwroot/",
    target = "10.0.0.2:/wwwroot/",
    delay  = 3,
    maxDelays = 30,
    delete = true,
    -- init = true,
    exclude = { "*.log", "var/log/*" },
    rsync = {
        archive = true,
        compress = true,
        bwlimit   = 2000,
        binary = "/usr/bin/rsync"
    }
}
sync {
    default.rsync,
    source = "/home/wwwroot/",
    target = "10.0.0.3:/wwwroot/",
    delay  = 3,
    maxDelays = 30,
    delete = true,
    -- init = true,
    exclude = { "*.log", "var/log/*" },
    rsync = {
        archive = true,
        compress = true,
        bwlimit   = 2000,
        binary = "/usr/bin/rsync"
    }
}
sync {
    default.rsyncssh,
    source = "/home/wwwroot/",
    host = "10.0.0.2",
    targetdir = "/home/wwwroot",
    delay  = 3,
    maxDelays = 30,
    delete = "true",
    -- init = true,
    exclude = { "*.log", "var/log/*" },
    rsync = {
        archive = true,
        compress = true,
--        bwlimit   = 2000,
        binary = "/usr/bin/rsync"
    }
}
```


rsync 模式
```conf
# 在对端机中应有 /etc/rsync.conf 的配置，不过虚拟机释放被删掉了，以后再补吧。
settings {
    pidfile = "/var/run/syncd.pid",
    logfile = "/var/log/lsyncd.log",
    statusFile = "/var/run/lsyncd.status",
    inotifyMode = "CloseWrite or Modify",
    maxProcesses = 100,
    insist = true
}
sync {
    default.rsync,
    source = "/opt/jc/",
    target = "jc@10.10.221.194::backup",
    delay  = 1,
    maxDelays = 3,
    delete = true,
    -- init = true,
    exclude = { ".git/*", "*.log", "var/cache/*", "var/composer_home/*", "var/log/*", "var/page_cache/*", "var/report/*", "var/session/*", "var/view_preprocessed/*", "storage/framework/*"},
    rsync = {
        archive = true,
--        compress = true,
--        binary = "/usr/bin/rsync",
        password_file = "/etc/rsyncd.pwd"
    }
}

; cat /etc/rsyncd.pwd 
; 123456
```
常见问题：
```bash
Aug 11 11:04:45 API lsyncd[125250]: 11:04:45 Error: Terminating since out of inotify watches.
Aug 11 11:04:45 API lsyncd[125250]: Consider increasing /proc/sys/fs/inotify/max_user_watches
# 用户最大 watch 文件：
# 修改方法1：echo 10008192 > /proc/sys/fs/inotify/max_user_watches（修改后，Linux系统重启inotify配置max_user_watches无效被恢复默认值8192）
# 修改方法2：vim /etc/sysctl.conf 
# 注意添加的内容：
# fs.inotify.max_user_watches=99999999（你想设置的值，此方法修改后重启linux，max_user_watches值不会恢复默认值8192）
```
参考资料
三种demo + 配置说明：https://www.cnblogs.com/lvzhenjiang/p/14411173.html
password 说明： https://www.cnblogs.com/lvzhenjiang/p/14198841.html
delete + settings 说明：https://blog.csdn.net/wuxingge/article/details/100798315
貌似还能配合脚本使用：https://blog.51cto.com/ckl893/1788292
官方文档精译：https://www.cnblogs.com/sunsky303/p/8976445.html