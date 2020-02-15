## 内存优化
### 需求

系统的物理内存是有限的，而对内存的需求是变化的, 程序的动态性越强，内存管理就越重要，选择合适的内存管理算法会带来明显的性能提升。
比如nginx， 它在每个连接accept后会malloc一块内存，作为整个连接生命周期内的内存池。 当HTTP请求到达的时候，又会malloc一块当前请求阶段的内存池, 因此对malloc的分配速度有一定的依赖关系。(而apache的内存池是有父子关系的，请求阶段的内存池会和连接阶段的使用相同的分配器，如果连接内存池释放则请求阶段的子内存池也会自动释放)。

### 目标

##### 一个优秀的通用内存分配器应具有以下特性:

- 额外的空间损耗尽量少
- 分配速度尽可能快
- 尽量避免内存碎片
- 缓存本地化友好
- 通用性，兼容性，可移植性，易调试


##### 内存管理可以分为三个层次，自底向上分别是：

- 操作系统内核的内存管理
- glibc层使用系统调用维护的内存管理算法
- 应用程序从glibc动态分配内存后，根据应用程序本身的程序特性进行优化， 比如使用引用计数std::shared_ptr，apache的内存池方式等等。
- 当然应用程序也可以直接使用系统调用从内核分配内存，自己根据程序特性来维护内存，但是会大大增加开发成本。

##### 三个通用内存分配器：ptmalloc、tcmalloc和jemalloc
- **glibc: ptmalloc2**
  ptmalloc2即是我们当前使用的glibc malloc版本。
- **Google：tcmalloc**
  tcmalloc是Google开源的一个内存管理库， 作为glibc malloc的替代品。目前已经在chrome、safari等知名软件中运用。
  根据官方测试报告，ptmalloc在一台2.8GHz的P4机器上（对于小对象）执行一次malloc及free大约需要300纳秒。而TCMalloc的版本同样的操作大约只需要50纳秒。
- **Facebook：Jemalloc**
  jemalloc是facebook推出的， 最早的时候是freebsd的libc malloc实现。 目前在firefox、facebook服务器各种组件中大量使用。

### 现状

目前大部分服务端程序使用glibc提供的malloc/free系列函数，而glibc使用的ptmalloc2在性能上远远弱后于google的tcmalloc和facebook的jemalloc。 而且后两者只需要使用LD_PRELOAD环境变量启动程序即可，甚至并不需要重新编译。

### 留给自己的问题
1. 大部分资料都在2014-2016年之间，至今为止是否还有必要去替换这个东西（因为阿里云等云服务商优化的已经足够好了）？
2. 另外谷歌code中的项目已经不在了，这个项目是否还在更新维护，是否还有未知的bug？
3. 看stackoverflow的回答说虽然性能很好(大概2-3倍)，但是会占用很多内存。对于java程序效果如何？（应用在怎样的场景下？nginx？）
4. tcmalloc和jmealloc的官网或git或源码在哪？
  [jemalloc官方网站（邮件列表在2016年9月退休）](http://jemalloc.net/)

### 参考资料
- [官方说明文档](http://goog-perftools.sourceforge.net/doc/tcmalloc.html)
- [github:gperftools（盲猜是tc的git）](https://github.com/gperftools/gperftools)
- [tcmalloc安装与使用](https://blog.csdn.net/u011217649/article/details/77683126)
- [为什么java程序占用那么多内存（解决方法）](https://blog.gavinzh.com/2018/07/31/why-the-java-program-take-up-so-much-memory/)
- [stackoverflow的解决方法](https://stackoverflow.com/questions/561245/virtual-memory-usage-from-java-under-linux-too-much-memory-used)
- [ptmalloc、tcmalloc与jemalloc对比分析](https://www.cyningsun.com/07-07-2018/memory-allocator-contrasts.html)
- [当Java虚拟机遇上Linux Arena内存池](https://cloud.tencent.com/developer/article/1054839)
- [tcmalloc原理剖析(基于gperftools-2.1)](http://gao-xiao-long.github.io/2017/11/25/tcmalloc/)
- [使用jemalloc来优化Nginx、MySQL内存管理](https://www.xiaoz.me/archives/12594)
