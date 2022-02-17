# kube-controller-manager 介绍

kube-controller-manager： Controller Manager还包括一些子控制器(副本控制器、节点控制器、命名空间控制器和服务账号控制器等)，控制器作为集群内部的管理控制中心，负责集群内的Node、Pod副本、服务端点（Endpoint)、命名空间 (Namespace)、服务账号(ServiceAccount)、资源定额 (ResourceQuota） 的管理，当某个Node意外宕机时，Controller Manager 会及时发现并执行自动化修复流程，确保集群中的pod副本始终处于预期的工作状态。

```tex
1.controller-manager控制器每间隔5秘检查一次节点的状态。
2.如果controller-manager控制器没有收到自节点的心跳，则将该node节点被标记为不可达。
3.controller-manager将在标记为无法访问之前等待40秒。
4.如果该node节点被标记为无法访问后5分钟还没有恢复，controller-manager会删除当前node节点的所有pod并在其它可用节点重建这些pod。
```

34:24

pod 高可用机制

