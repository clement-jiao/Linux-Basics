<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-02-15 22:36:06
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-03-07 21:24:11
 -->

### date 的昨天今天和明天

```bash
# 昨天的获取有两种方式：
yesterday=`date -d '1 days ago' +%Y%m%d`
yesterday2=`date -d yesterday +%Y%m%d`

# 今天是本周的第几天：
today=`date +%Y%m%d`
whichday=`date -d $today +%w`

# 当前周一：
# $today $whichday
monday=`date -d "$today -$[${whichday}-1] days" +%Y%m%d`

# 当前周日：
# $monday
sunday=`date -d "$monday+6 days" +%Y%m%d`

# 当月第一天：
firstdate=`date +%Y%m01`

# 当月最后一天：
lastdate=`date -d"$(date -d"1 month" +%Y%m01) -1 day" +%Y%m%d`
```
### 示例
```bash
#!/bin/bash
# 昨日
yesterday=`date -d '1 days ago' +%Y%m%d`
echo "yesterday is $yesterday."
yesterday2=`date -d yesterday +%Y%m%d`
echo "yesterday is $yesterday2 by 'date -d yesterday +%Y%m%d'."

# 今日
today=`date +%Y%m%d`
echo "today is $today."

# 当前周的第几天
whichday=$(date -d $today +%w)
echo "today is $whichday day of this week."

# 当周的周一
monday=`date -d "$today -$[${whichday}-1] days" +%Y%m%d`

# 当周的周日
sunday=`date -d "$monday+6 days" +%Y%m%d`
echo "monday is $monday of this week."
echo "sunday is $sunday of this week."

# 当月第一天(这里取巧用了01直接代替当月第一天的日期)
firstdate=`date +%Y%m01`
echo "the firstday of this month is $firstdate."

# 当月最后一天(当月第一天的后一个月第一天的前一天就是当月最后一天，有点绕)
lastdate=`date -d"$(date -d"1 month" +%Y%m01) -1 day" +%Y%m%d`
echo "the lastday of this month is $lastdate."

# 今天是今年的第多少周
./week.sh 2018-09-01
num1=`date -d $1 +%U`
num2=`date -d $1 +%V`
echo "Start with Sunday as a week,"$1" week number is "$num1;
echo "Start with Monday as a week,"$1" week number is "$num2;
```
### 在定时任务中的使用

```bash
# `date +"\%Y\%m\%d_\%H:\%M"`
# 或
# $(date +"\%Y\%m\%d_\%H:\%M")
 ```
