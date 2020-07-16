<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-07-13 10:44:23
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-07-13 13:56:28
-->

### 传说中最好用的时间处理模块

### 踩坑指南
1. 这个鬼东西不能对时间进行加减运算, 如果有这方面的需求还请看datetime.
2. 虽然不能进行加减运算, 但是进行比较运算还是很好用的, 以及对时间推移等.
3. 可以通过比较运算及时间推移对固定时间差进行比较,以得出True或False.
4. arrow.get转换出的对象是utc时间, 内置参数可以转换时区,可以去官方文档去找找

#### 官方文档
[官方文档: https://arrow.readthedocs.io/en/stable/](https://arrow.readthedocs.io/en/stable/)

[GitHub: https://github.com/crsmithdev/arrow](https://github.com/crsmithdev/arrow)

### 获取时间
1. 可以很轻松的获取UTC的标准时间，这样在处理时间的时候就可以直接获取UTC的标准时间。
```python
utc = arrow.utcnow()
utc_format = utc.format('YYYY-MM-DD HH:mm:ss')
print(utc_format)
```
2. 通过 Arrow 获取标准的 Asia/Shanghai 时间
```python
utc = arrow.utcnow()
utc = utc.to("Asia/Shanghai")   # 转换成Asia/Shanghai时间
utc_Shanghai = utc.format('YYYY-MM-DD HH:mm:ss')
print(utc_Shanghai)
```
3. 时间推移，我们可以通过这个模块获取未来的时间、或者过去的时间。
1） 未来几分钟，或者过去几分钟
```python
utc = arrow.utcnow().to("Asia/Shanghai")    # 转换成Asia/Shanghai时间
utc = utc.shift(minutes=-5)                 # -5 代表过去的分钟, +5 代表未来的分钟
utc = utc.shift(hours=-5)                   # -5 代表过去的小时, +5 代表未来的小时
utc = utc.shift(days=-1)                    # -1 代表过去的天,   +5 代表未来的天
utc = utc.shift(weeks=-1)                   # -1 代表过去的周,   +1 代表未来的周
utc = utc.shift(months=-5)                  # -1 代表过去的月,   +1 代表未来的月
utc = utc.shift(years=-5)                   # -5 代表过去的年,   +5 代表未来的年
utc_Shanghai = utc.replace(hours=+8).format('YYYY-MM-DD HH:mm:ss')  # +8 可以转换成Asia/Shanghai时间
print(utc_Shanghai)
```

4. 范围和跨度：
获取任何单位的时间跨度：
```python
arrow.utcnow().span('hour')
(<Arrow [2013-05-07T05:00:00+00:00]>, <Arrow [2013-05-07T05:59:59.999999+00:00]>)
```
或者只是获得最低和最高时间：
```python
arrow.utcnow().floor('hour')
<Arrow [2013-05-07T05:00:00+00:00]>

arrow.utcnow().ceil('hour')
<Arrow [2013-05-07T05:59:59.999999+00:00]>
```
还可以获得一个时间范围：
```python
start = datetime(2013, 5, 5, 12, 30)
end = datetime(2013, 5, 5, 17, 15)
for r in arrow.Arrow.span_range('hour', start, end):
    print(r)

(<Arrow [2013-05-05T12:00:00+00:00]>, <Arrow [2013-05-05T12:59:59.999999+00:00]>)
(<Arrow [2013-05-05T13:00:00+00:00]>, <Arrow [2013-05-05T13:59:59.999999+00:00]>)
(<Arrow [2013-05-05T14:00:00+00:00]>, <Arrow [2013-05-05T14:59:59.999999+00:00]>)
(<Arrow [2013-05-05T15:00:00+00:00]>, <Arrow [2013-05-05T15:59:59.999999+00:00]>)
(<Arrow [2013-05-05T16:00:00+00:00]>, <Arrow [2013-05-05T16:59:59.999999+00:00]>)

```
或者只是遍历一段时间：
```python
>>> start = datetime(2013, 5, 5, 12, 30)
>>> end = datetime(2013, 5, 5, 17, 15)
>>> for r in arrow.Arrow.range('hour', start, end):
...     print(repr(r))
...
<Arrow [2013-05-05T12:30:00+00:00]>
<Arrow [2013-05-05T13:30:00+00:00]>
<Arrow [2013-05-05T14:30:00+00:00]>
<Arrow [2013-05-05T15:30:00+00:00]>
<Arrow [2013-05-05T16:30:00+00:00]>
```
