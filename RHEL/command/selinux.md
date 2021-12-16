### selinux

### 查看布尔值

```bash
[root@centos8 ~]# semanage boolean --list/-l
usage: semanage boolean [-h] [-n] [-N] [-S STORE] [  --extract  | --deleteall  | --list -C | --modify ( --on | --off ) boolean ]
positional arguments:
  boolean               boolean

optional arguments:
  -h, --help               show this help message and exit
  -C, --locallist          列出 boolean 本地定制
  -n, --noheading          列出 boolean 对象类型时不打印头
  -N, --noreload           提交后不要重新加载策略
  -S STORE, --store STORE  选择一个备选的 SELinux 策略存储来进行管理
  -m, --modify             修改 boolean 对象类型的一个记录
  -l, --list               列出 boolean 对象类型的记录
  -E, --extract            提取可定制的命令以在事务中使用
  -D, --deleteall          删除所有 boolean 对象的本地定制
  -1, --on                 启用布尔
  -0, --off                禁用布尔
semanage boolean: error: one of the arguments -m/--modify -l/--list -E/--extract -D/--deleteall is required
```

### 设置布尔值

```bash
[root@centos8 ~]# setsebool -P samba_create_home_dirs on/off
[root@centos8 ~]# semanage boolean -l|grep samba
samba_create_home_dirs     (开,开)  Allow samba to create home dirs
samba_domain_controller    (关,关)  Allow samba to domain controller
samba_enable_home_dirs     (关,关)  Allow samba to enable home dirs
samba_export_all_ro        (关,关)  Allow samba to export all ro
```



