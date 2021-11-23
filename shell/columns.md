### top -c 输出重定向到文件，内容不完整解决

```bash
# 在脚本中加入环境变量解决

#!/bin/bash
export COLUMNS=200
/usr/bin/top -cn1  -b -u smsplatform  >/tmp/top.log
```

参考资料：
1. [top -c 输出重定向到文件，内容不完整解决](https://blog.csdn.net/weixin_42123737/article/details/104677552)
2. [linux下使用shell脚本获取终端宽度)](https://www.cnblogs.com/sgdream/p/9932766.html)
