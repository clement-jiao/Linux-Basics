[toc]

Pod 控制器：

- ReplicationController：基础扩缩容控制器
- ReplicaSet：基于 ReplicationController 向上扩展的控制器
- Deployment
- DaemonSet：在每个 **节点** 中只运行一个指定的 pod 副本
  - 以上 pod 副本均为无状态的、守护进程类的必须始终持续在后台服务

- Job：仅运行一次即销毁，例如数据库备份任务，需要状态为 completed，完成任务退出而不是异常退出。
- cronjob：周期性运行 job，需要状态为 completed，完成任务退出而不是异常退出。
- StateFulSet：能够实现管理有状态应用，每一个应用每一个 pod 副本都是单独管理的，拥有自己独立的标识和数据集
- TPR： Third Party Resources 第三方资源
- CDR：Custom Defined Resources，自定义资源。1.8+

Helm：

