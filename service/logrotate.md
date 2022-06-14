### logrotate

```conf
/var/log/log-file {
    monthly
    rotate 5
    dateext
    dateformat .%s
    create 644 root root
    postrotate
        /usr/bin/killall -HUP rsyslogd
    endscript
}
```



https://linux.cn/article-4126-1.html

# dateformat 详解
https://blog.csdn.net/qq_34246164/article/details/89065310

