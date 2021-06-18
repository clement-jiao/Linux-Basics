## python 打印变量名

### 终极解决方法
[在stackoverflow上找到的答案](https://stackoverflow.com/questions/592746/how-can-you-print-a-variable-name-in-python#)

```python
import inspect, re

def varname(p):
  for line in inspect.getframeinfo(inspect.currentframe().f_back)[3]:
    m = re.search(r'\bvarname\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)', line)
    if m:
      return m.group(1)


spam = 42
print(varname(spam))

>>> spam
```


### 自行编写
```python
aa = 1
print(aa)

>>> 1
```


使用print简单打印变量的时候，只会显示变量名对应的值，并不会打印变量名，那如何才能打印变量名呢？

python中内置locals()是打印变量名的关键。

```python
aa = 1
print(locals())

>>> {..., 'aa': 1, '__name__': '__main__', '__spec__': None,...}  
```

可以看到变量aa的名字被保存在此字典中，所以我们可以通过逐一检查字典的值是否和变量aa指向的值是同一个值来得到变量名。
```python
def var_name(var,all_var=locals()):
    return [var_name for var_name in all_var if all_var[var_name] is var][0]

aa = 11
bb = 22
cc = 33
dd = 44
print(var_name(aa))
print(var_name(bb))
print(var_name(cc))
print(var_name(dd))


>>> aa
>>> bb
>>> cc
>>> dd
```

在函数头里面使用locals()作为默认参数，得到的字典是外部的局部变量参数字典。


### 非首次引用出现的问题
但是这样做会存在问题，那就是当多个变量名指向同一个值的时候就会发错名字混乱。
```python
def var_name(var, all_var=locals()):
    return [var_name for var_name in all_var if all_var[var_name] is var][0]


aa = bb = 11
cc = dd = 22
print(var_name(aa))
print(var_name(bb))
print(var_name(cc))
print(var_name(dd))

>>> aa
>>> bb
>>> cc
>>> dd
```
所以只能当变量的值只被引用一次的时候才可以这么用。