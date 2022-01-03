### CMD 与 ENTRYPOINT 的区别

CMD：镜像启动为一个容器时候的默认命令或脚本，CMD ["/bin/bash"]

ENTRYPOINT： 也可以用于定义容器在启动时候默认执行的命令或者脚本，如果是和CMD 命令混合使用的时候，会将CMD的命令当做参数传递给 ENTRYPOINT 后面的脚本，可以在脚本中对参数做判断并相应的容器初始化操作。

```bash
entrypoint ["top", "-b"] == \
entrypoint ["top", "-b", "-c"] CMD ["-c"] == \
entrypoint ["top", "$1", "$2"] CMD ["-b", "-c"]

entrypoint ["docker-entrypoint.sh"]	# 定义一个入口点脚本，并传递 mysqld 参数 CMD["mysqld"]

entrypoint ["docker-entrypoint.sh","mysqld"]

entrypoint(脚本) + cmd (当做参数传递给entrypoint)

iptables -t nat -vnL
pstree -p 1
```

docker limit 

```bash
/sys/fs/cgroup/cpu,cpuacct/docker/$dockerid/

cpu.cfs_quota_us: 100000 = 100% * 1000 cpus		# docker_quota
```



#### 思考

1. 容器是运行环境，如果环境中没有任务执行他就退出了