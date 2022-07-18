### 提取 rpm 包中文件
```bash
rpm2cpio elasticsearch-7.17.5-x86_64.rpm | cpio -div ./usr/lib/systemd/system/elasticsearch.service

# rpm2cpio [package] | cpio -div .[/xx/file]
# 不是很理解为什么要在这加 “.”
```

https://www.cnblogs.com/liuyuelinfighting/p/15564569.html