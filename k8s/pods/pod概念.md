[toc]

## Pod 概念

### Pod 对象的阶段/相位(phase)

pod 对象总是应该处于其声明进程中以下几个阶段/相位(phase) 之一

- Pending：`API Server` 创建了 Pod 资源对象并已存入 etcd 中，但尚未被调度完成，或仍处于从仓库下载镜像的过程中；
- Running：Pod 已经被调度之某节点，并且所有容器都已经被 kubelet 创建完成；
- Successed：Pod 中的所有容器都经成功终止并且不会被重启；
- Failed：所有容器都已经终止，但至少有一个容器终止失败，即容器返回了非0值的退出状态或已经被系统终止；
- Unknown：`API Server` 无法正常获取到 Pod 对象的状态信息，通常是由于其无法与所在工作节点的 kubelet 通信所致。

### Pod 对象的创建过程

> [图解kubernetes Pod创建流程大揭秘_Kubernetes中文社区](https://www.kubernetes.org.cn/6766.html)

1. 当用户提交创建请求给 `API Server`，`API Server` 接收到请求先将没指定的字段使用默认值进行填充补全(准入控制)，然后将定义信息存储到 etcd 中，etcd 存储完成定义信息将结果返回给 ``API Server``，``API Server`` 返回创建状态返回给前端用户。
2. 















