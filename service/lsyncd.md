
## lsyncd
要求 rsync 版本大于 3.1，一般默认版 3.1.2。


```conf
settings {
    pidfile = "/var/run/syncd.pid",
    logfile = "/var/log/lsyncd.log",
    statusFile = "/var/run/lsyncd.status",
    inotifyMode = "CloseWrite or Modify",
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
```

参考资料
三种demo + 配置说明：https://www.cnblogs.com/lvzhenjiang/p/14411173.html
password 说明： https://www.cnblogs.com/lvzhenjiang/p/14198841.html
delete + settings 说明：https://blog.csdn.net/wuxingge/article/details/100798315
貌似还能配合脚本使用：https://blog.51cto.com/ckl893/1788292
官方文档精译：https://www.cnblogs.com/sunsky303/p/8976445.html