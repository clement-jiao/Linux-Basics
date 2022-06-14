### 资源限制概括

1. 对单个容器的 cpu 及 memory 实现资源限制
2. 对单个 pod 的 cpu 及 memory 实现资源限制
limit Range：对具体某个 pod 或容器的资源使用进行限制
限制 namespace 中每个 pod 或容器的最小与最大计算资源；
限制 namespace 中每个 pod 或容器计算资源 request、limit 之间的比例；
限制 namespace 中每个存储卷声明（PersistentVolumeClaim）可使用的最小与最大存储空间；
设置 namespace 中容器默认计算资源的 request、limit，并在运行时自动注入到容器中。
官方文档：https://kubernetes.io/zh/docs/concepts/policy/limit-range

3. 对整个 namespace 的 cpu 及 memory 实现资源限制


