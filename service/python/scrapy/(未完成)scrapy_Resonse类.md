<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-06-22 15:45:04
 * @LastEditors: clement-jiao
 * @LastEditTime: 2020-06-23 14:53:12
-->
[toc]
## Response类
- 属性相关：
  - body 响应的字节数据
  - text 响应的编码之后的文本数据
  - headers 响应头部信息，是字节数据
  - encoding 相应数据的编码字符集
  - status 响应的状态码
  - url 请求的URL
  - request 请求对象
  - meta 元数据，用于request和callback回调函数之间传值
- 解析相关
  - selector()
  - css() 样式选择器
  - xpath() xpath路径

## scrapy框架
### 五大组件两个中间件
- engine 核心引擎
- spider 爬虫类
- scheduler 调度器
- Downloader 下载器
- itempipeline 数据管道
- 爬虫中间件、下载中间件


### scrapy指令
- 创建爬虫项目：scrapy startproject 项目名
- 生成爬虫文件：scrapy genspider 爬虫名:baidu 域名:baidu.com
- 启动爬虫项目：scrapy crawl 爬虫名
  - -o 保存：保存数据到指定的文件中
  - -s 信号：(closespider_itemcount=30)
- 爬虫 shell  ：scrapy shell [url]
  - fetch(url)
  - view(response)
  - request : scrapy.http.request
  - response: scrapy.Response| HtmlResponse
  - scrapy

### Response对象的属性或方法
- body | text | encoding | status | url | request | heades | meta
- xpath() | css() | -> scrapy.selector.Selector.SelectorList[Selector]
  - extract()
  - get()
  - extract_first()
- css() 中表达式
  - 样式选择器[::text|attr("属性名")]
- xpath() 中表达式
  - 同 lxml的xpath表达式相同

### Request初始化参数
- URL
- callback： 如果为指定，则默认为parse
- priority： 优先级的权限值，值高优先级高
- meta：     元数据，cookies等数据
- headers：  请求头
- dont_filter： 是否过滤重复的URL，True不过滤，False过滤。

## scrapy 数据管道
### 指令方式存储
```scrapy crawl 爬虫名 -o xxx.json|csv```
只适合单页数据爬取，如果多页多层次数据爬取时，不适合次方式。

### item类
作用：用于区别哪 一页（类型）的数据
用法：类似于dict用法，在数据管道类的process_item()方法中，通过isinstance()方法类判断item是那一类型的s


















