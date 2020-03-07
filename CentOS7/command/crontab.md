<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-03-07 21:24:59
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-03-07 21:57:07
 -->
### crontab定时任务

#### 语法
```bash
crontab [ -u user ] file

# 或
crontab [ -u user ] { -l | -r | -e }

# 参数说明：
# -e : 执行文字编辑器来设定时程表，内定的文字编辑器是 VI，如果你想用别的文字编辑器，则
#      请先设定 VISUAL 环境变数来指定使用那个文字编辑器(比如说 setenv VISUAL joe)
# -r : 删除目前的时程表
# -l : 列出目前的时程表
# -i : 删除前需要先确认
```

#### crontab中的输出配置
```html
crontab中经常配置运行脚本输出为：>/dev/null 2>&1，来避免crontab运行中有内容输出。

shell命令的结果可以通过'>'的形式来定义输出

/dev/null 代表空设备文件　　

'>' 代表重定向到哪里，例如：echo "123" > /home/123.txt　

1 表示stdout标准输出，系统默认值是1，所以">/dev/null"等同于"1>/dev/null"

2 表示stderr标准错误

& 表示等同于的意思，2>&1，表示2的输出重定向等同于1　

那么重定向输出语句的含义：

1>/dev/null 首先表示标准输出重定向到空设备文件，也就是不输出任何信息到终端，不显示任何信息。

2>&1 表示标准错误输出重定向等同于标准输出，因为之前标准输出已经重定向到了空设备文件，所以标准错误输出也重定向到空设备文件。

注意：当程序在你所指定的时间执行后，系统会寄一封信给你，显示该程序执行的内容。
若是你不希望收到这样的信，请在每一行空一格之后加上: ``` > /dev/null 2>&1``` 即可
```

#### 其他应该注意的问题
1. 新创建的cron job，不会马上执行，至少要过2分钟才执行。如果重启cron则马上执行。

2. 每条 JOB 执行完毕之后，系统会自动将输出发送邮件给当前系统用户。日积月累，非常的多，甚至会撑爆整个系统。所以每条 JOB 命令后面进行重定向处理是非常必要的： >/dev/null 2>&1 。前提是对 Job 中的命令需要正常输出已经作了一定的处理, 比如追加到某个特定日志文件。

3. 当crontab突然失效时，可以尝试/etc/init.d/crond restart解决问题。或者查看日志看某个job有没有执行/报错tail -f /var/log/cron。

4. 千万别乱运行crontab -r。它从Crontab目录（/var/spool/cron）中删除用户的Crontab文件。删除了该用户的所有crontab都没了。

5. 在crontab中%是有特殊含义的，表示换行的意思。如果要用的话必须进行转义\%，如经常用的 date ‘+%Y%m%d’ 在 crontab 里是不会执行的，应该换成$(date +"\%Y\%m\%d")。


#### 示例

1. 每月每天每小时的第 0 分钟执行一次 /bin/ls
  ```0 * * * * /bin/ls -hla ```
2. 在 12 月内, 每天的早上 6 点到 12 点，每隔 3 个小时 0 分钟执行一次 /usr/bin/backup
  ```0 6-12/3 * 12 * /usr/bin/backup```
3. 周一到周五每天下午 5:00 寄一封信给 alex@domain.name
  ```0 17 * * 1-5 mail -s "hi" alex@domain.name < /tmp/maildata```
4. 每月每天的午夜 0 点 20 分, 2 点 20 分, 4 点 20 分....执行 echo "haha"
  ```20 0-23/2 * * * echo "haha"```
5. 下面再看看几个具体的例子：
    ```bash
    # 将程序输出重定向到log文件，错误重定向到空设备文件
    0 */3 * * * nohup /root/../python3 /workspace/../weibo.py \
    > /workspace/../logs/$(date +"\%Y\%m\%d")/$(date +"\%Y\%m\%d_\%H:\%M").log 2>/dev/null

    # 每两个小时重启一次apache
    0 */2 * * * /sbin/service httpd restart

    # 每天7：50开启ssh服务
    50 7 * * * /sbin/service sshd start

    # 每天22：50关闭ssh服务
    50 22 * * * /sbin/service sshd stop

    # 每月1号和15号检查/home 磁盘
    0 0 1,15 * * fsck /home

    # 每小时的第一分执行 /home/bruce/backup这个文件
    1 * * * * /home/bruce/backup

    # 每周一至周五3点钟，在目录/home中，查找文件名为*.xxx的文件，并删除4天前的文件。
    00 03 * * 1-5 find /home "*.xxx" -mtime +4 -exec rm {} \;

    # 每月的1、11、21、31日是的6：30执行一次ls命令
    30 6 */10 * * ls
    ```














