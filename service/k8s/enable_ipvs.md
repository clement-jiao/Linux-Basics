

### 启用 ipvs 内核模块



创建内核模块载入脚本文件 /etc/sysconfig/modules/ipvs.modules ，设定自动载入的内核模块。内容如下：

```bash
#!/bin/bash
# /etc/sysconfig/modules/ipvs.modules

ipvs_mods_dir="/usr/lib/modules/$(uname -r)/kernel/net/netfilter/ipvs"
for mod in $(ls $ipvs_mods_dir|grep -o "^[^.]*"); do
		/sbin/modinfo -F filename $mod &> /dev/null
		if [ $? -eq 0 ]; then
				/sbin/modprobe $mod
		fi
done
```





