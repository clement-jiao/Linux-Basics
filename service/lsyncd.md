
## lsyncd
要求 rsync 版本大于 3.1，一般默认版 3.1.2。


```conf
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
    delete = "true", #
    -- init = true,
    exclude = { "*.log", "var/log/*" },
    rsync = {
        archive = true,
        compress = true,
        bwlimit   = 2000,
        binary = "/usr/bin/rsync"
    }
}
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