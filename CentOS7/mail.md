## 批量删除mail


```bash
# 注意是' 不是"
echo 'd *'|mail 

# 根据关键字删除（为啥没 d ？）
echo '"(Cron Daemon)"'|mail

# 只删除某个定时任务的邮件
echo 'd /命令关键字'|mail 
```
http://blog.lujun9972.win/blog/2020/05/25/%E5%A6%82%E4%BD%95%E6%89%B9%E9%87%8F%E5%88%A0%E9%99%A4linux-mail%E4%B8%AD%E7%9A%84cron%E9%82%AE%E4%BB%B6/index.html