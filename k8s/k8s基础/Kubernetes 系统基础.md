# 【第 1 章】 Kubernetes 系统基础

近十几年来，IT领域新技术，新概念层出不穷，例如云计算、 DevOps 、微服务、容器和云原生等，直有"乱花渐欲迷人眼"之势。另外，出于业务的需要， IT 应用模型也在不断变革，例如开发模式从瀑布式到敏捷再到精益，甚至是与 QA 和 Operations 统一的 DevOps，应用程序架构从单体模型到分层再到微服务，部署及打包方式从面向物理机到虚拟机再到容器，应用程序的基础架构从自建机房到托管再到云计算等，这些变革使得IT技术应用效率大大提升，同时实现了以更低的成本交付更高质量的产品。

一方面，尤其是以 Docker 为代表的容器技术的出现，终结了 DevOps 中交付和部署环节因环境、配置及程序本身的不同而造成的动辄几种甚至十几种部署配置的困境，将它们统一在了容器镜像之上。如今，越来越多的企业或组织开始选择以镜像文件作为交付载体。容器镜像之内直接包含了应用程序及其依赖的系统环境、库、基础程序等，从而能够在容器引擎上直接运行。于是，IT 运维工程师无须再关注开发应用程序的编程语言、环境配置等，甚至连业务逻辑本身也不必过多关注，而只需要掌握容器管理的单一工具链即可。

另一方面，这些新技术虽然降低了部署的复杂度，但以容器格式运行的应用程序间的协同以大规模容器应用的治理却成为一个新的亟待解决的问题，这种需求在微服务架构中表现的尤为明显。微服务通过将传统的巨大单体应用拆分为众多目标单一的小型应用以解耦程序的核心功能，各微服务可独立部署和扩展。随之而来的问题便是如何为应用程序提供一个一致的环境，并合理、高效地将各微服务实例及副本编排运行在一组主机之上，这也正是以 Kubernetes 为代表的容器编排工具出现的原因。本章将在概述容器技术之后讲解 Kubernetes 编排系统的核心概念、关键组件以及基础运行逻辑。

## 1.1　容器与容器编排系统

容器技术由来已久，却直到几十年后因 dotCloud 公司（后更名为 Docker）于 Docker 项目中发明的 "容器镜像" 技术创造性地解决了应用打包的难题才焕发出新的生命力并以 "应用容器" 的面目风靡于世，Docker 的名字更是响彻寰宇，他催生出或改变了一大批诸如容器编排、服务网格和云原生等技术，深刻影响了云计算领域的技术方向。

### 1.1.1　Docker容器技术

概括起来，Docker 容器技术有3个核心概念：容器、镜像和镜像仓库 (Docker Registry)。如果把容器类比为动态的、有生命周期的进程，则镜像就像是静态的可执行程序及其运行环境的打包文件，而镜像仓库则可想象成应用程序分发仓库，事先存储了制作好的各类镜像文件。

运行 Docker 守护进程（daemon）的主机称为 Docker 主机，它提供了容器引擎并负责管理本地容器的生命周期，而容器的创建则要基于本地存储的 Docker 镜像进行，当本地缺失所需的镜像时，由守护进程负责到 Docker Registry 获取。Docker 命令行客户端（名为docker）通过 Docker 守护进程提供的 API 与其交互，用于容器和镜像等的对象管理操作。

**Docker 各组件间的逻辑架构及交互关系如图 1-1所示。**

![](C:\Users\admin\Documents\devops\Linux-Basics\k8s\k8s基础\._images\Kubernetes 系统基础\1-1Docker逻辑架构.jpg)

任何拥有 Docker 运行时引擎的主机都能够根据同一个镜像创建并启动运行环境完全一致的容器，在容器中添加新数据或修改现有数据的结果都存储在由容器附加在镜像之上的可写顶层中。因此，同一 Docker 主机上的多个容器可以共享同一基础镜像，但各有自己的数据状态。Docker 使用 aufs、devicemapper、overlay2 等存储驱动程序来管理镜像层和可写容器层的内容，尽管每种存储驱动程序实现的管理方式不尽相同，但它们都使用可堆的镜像层和写时复制(CoW)策略。

删除容器会同时删除其创建的可写顶层，这将会导致容器生成的状态数据全部丢失。Docker支持使用存储卷（volume）技术来绕过存储驱动程序，将数据存储在宿主机可达的存储空间上以实现跨容器生命周期的数据持久性，也支持使用卷驱动器（Docker引擎存储卷插件）将数据直接存储在远程系统上，如图1-2所示。

![](C:\Users\admin\Documents\devops\Linux-Basics\k8s\k8s基础\._images\Kubernetes 系统基础\1-2Docker存储卷.jpg)

拥有独立网络名称空间的各容器应用间通信将依赖于名称空间中可使用设备及相关的 IP 地址、路由和 iptables 规则等网络配置。Linux内核支持多种类型的虚拟网络设备，例如Veth、Bridge、802.q VLAN device和TAP等，并支持按需创建虚拟网络设备并组合出多样化的功能和网络拓扑。Docker借助虚拟网络设备、网络驱动、IPAM（IP地址分配）、路由和iptables等实现了桥接模式、主机模式、容器模式和无网络等几种单主机网络模型。

**图 1-3 显示了 Docker 默认的桥接网络拓扑。**

![](C:\Users\admin\Documents\devops\Linux-Basics\k8s\k8s基础\._images\Kubernetes 系统基础\1-3Docker默认的桥接网络拓扑.jpg)

对于跨主机的容器间互联互通需求，Docker默认通过端口映射（DNAT）进行，这需要将容器端口暴露给宿主机，且将服务端的容器地址设置为对客户端不可见。然而，生产环境中部署、运行分布式应用对于构建跨主机容器网络几乎是必然需求。目前，封包（Overlay Network）和路由（routing network）是常见的跨主机容器间通信的解决方案，前一种类型中常见的协议有VXLAN、IPIP隧道和GRE等。2015年3月，Docker收购了SDN初创公司SocketPlane，并由此创建了CNM（Container Network Model）及其由Docker中剥离出来的单独网络实现 libnetwork，该实现使用驱动程序/插件模型支持许多基础网络技术，如 IP VLAN、MAC VLAN、Overlay、Bridge 和 Host 等。

### 1.1.2　OCI与容器运行时

OCI（Open Container Initiative，开放工业标准）的容器运行时规范设定的标准定义了容器运行状态的描述，以及运行时需要提供的容器管理功能，例如创建、删除和查看等操作。容器运行时规范不受上层结构绑定，不受限于任何特定操作系统、硬件、CPU架构或公有云等，从而允许任何人遵循该标准开发应用容器技术。OCI 项目启动后，Docker 公司将2014 年开源的 libcontainer 项目移交至OCI组织并进化为 runC 项目，成为第一个且目前接受度最广泛的遵循 OCI 规范的容器运行时实现。

为了兼容OCI规范，Docker项目自身也做了架构调整，自1.11.0版本起，Docker引擎由一个单一组件拆分成了Docker Engine（docker-daemon）、containerd、containerd-shim和runC等4个独立的项目，并把 containerd 捐赠给了CNCF。

containerd是一个守护进程，它几乎囊括了容器运行时所需要的容器创建、启动、停止、中止、信号处理和删除，以及镜像管理（镜像和元信息等）等所有功能，并通过 gRPC 向上层调用者公开其 API，可被兼容的任何上层系统调用，例如 Docker Engine 或 Kubernetes 等容器编排系统，并由该类系统负责镜像构建、存储卷管理和日志等其他功能。
然而，containerd只是一个高级别的容器运行时，并不负责具体的容器管理功能，它还需要向下调用类似 runC 一类的低级别容器运行时实现此类任务。containerd 又为其自身和低级别的运行时（默认为runC）之间添加了一个名为containerd-shim的中间层，以支持多种不同的OCI运行时，并能够将容器运行为无守护进程模式。这意味着，每启动一个容器，containerd都会创建一个新的containerd-shim进程来启动一个runC进程，并能够在容器启动后结束该runC进程。

**如图 1-4 所示 Docker项目组件架构与运行容器的方式。**

<img src="C:\Users\admin\Documents\devops\Linux-Basics\k8s\k8s基础\._images\Kubernetes 系统基础\1-4Docker引擎的组件.jpg" style="zoom:50%;" />

近年来，出于各种设计目标的容器运行时项目越来越多，较主流的有 CRI-O、Podman 和 Kata Containers 等。CRI-O是一款类似于 containerd 的高级运行时，在底层同样需要调用低级运行时负责具体的容器管理任务，支持与 OCI 兼容的运行时（目前使用runC）。它为 Kubernetes CRI（容器运行时接口）提供了轻量级的容器运行方案，核心目标是在kubelet 和 OCI 运行时之间提供一个黏合层，支持从 Kubernetes 直接运行容器（无须再依赖任何其他代码或工具），以取代有着较长集成链路的 Docker 容器引擎。

> 提示：关于更多Kubernetes CRI和kubelet相关的话题，后续会有相应的介绍。

由 Red Hat 主要推动和维护的 Podman 项目则是另一款兼容 OCI 规范的高级容器运行时，它起初是 CRI-O 项目的一部分，后来单独分离成为 libpod 项目， Podman 是相关的命令行管理工具。Podman 在管理容器时使用无守护进程模型，它直接通过runC容器运行时进程（而非守护程序）与镜像 Registry、容器和镜像存储以及 Linux 内核直接交互。它支持管理容器的整个生态系统，包括 Pod（Kubernetes 引入的组件，由关系紧密的容器组成的容器集）、容器、容器镜像，以及使用 libpod 库的存储卷。Podman 用于构建镜像的功能则交由 Buildah 项目完成，支持基于 Dockerfile 构建镜像的podman build 命令仅包含该项目的一个子集，使用 bash 脚本构建镜像是该项目更大的亮点。镜像 Registry 也有一个专用的项目 Skopeo ，支持 Docker 镜像和OCI镜像的签名、存储及推拉操作。

> 提示：Podman 的命令格式与 Docker命令几乎完全兼容，用户可直接迁移 Docker命令行至 Podman 上。

与最初的Docker项目一样，CoreOS 开发的 rkt 同时提供了高级容器运行时和低级容器运行时的功能。例如，它支持构建容器镜像、于本地存储库中获取和管理镜像，并通过命令将之启动为容器等。不过，它没有守护进程和远程可用的API。为了同 Docker 竞争，rkt 还创建了应用程序容器（appc）标准以替代 OCI，但未获得广泛采用。其他常见的容器运行时还有 frakti 和 LXC 等。

Docker 和 rkt 都是经典容器技术的实现，同一主机上的各容器共享内核，轻量、快速，但也因隔离性差、内核版本绑定（容器应用受限于容器引擎宿主机的内核版本）以及不支持异构的硬件平台等原因为人诟病。所以，基于虚拟化或者独立内核的安全容器项目悄然兴起，2017年底，由 Intel Clear Container 和 Hyper.sh RunV 项目合并而来的 Kata Containers 就是代表之一。Kata Containers 在专用的精简内核中运行容器，提供网络、I/O 和内存的隔离，并可以通过虚拟化 VT 扩展进行硬件强制隔离，因而更像一个传统的、精简版的或轻量化的虚拟机，如图1-5所示。但 Kata Containers又是一个容器技术，支持 OCI 规范和 Kubernetes CRI 接口，并能够提供与标准 Linux 容器一致的性能。Kata Containers致力于通过轻量级虚拟机来构建安全的容器运行时，因而也更适用于多租户公有云，以及对项目隔离有着较高标准的私有云场景。

<img src="C:\Users\admin\Documents\devops\Linux-Basics\k8s\k8s基础\._images\Kubernetes 系统基础\1-5经典容器与Kata Container.jpg" style="zoom:80%;" />

### 1.1.3　为什么需要容器编排系统

Docker本身非常适合管理单个容器，若运行的是构建于有限几个或十几个容器上的应用程序，则可以仅在Docker引擎上自主运行，部署和管理这些容器并不会遇到太大的困难。然而，对于包含成百上千个容器的企业级应用程序来说，这种管理将变得极其复杂，甚至无法实现。

容器编排是指自动化容器应用的部署、管理、扩展和联网的一系列管控操作，能够控制和自动化许多任务，包括调度和部署容器、在容器之间分配资源、扩缩容器应用规模、在主机不可用或资源不足时将容器从一台主机迁移到其他主机、负载均衡以及监视容器和主机的运行状况等。

容器编排系统用于完成容器编排相关的任务。以 Kubernetes、Mesos 和 Docker Swarm 等为代表的这类工具通常需要用户在 YAML 或 JSON 格式的配置清单中描述应用程序的配置，以指示编排系统在何处检索容器镜像（私有仓库或者某外部仓库）、如何在容器之间建立网络、在何处存储日志以及如何挂载存储卷等。确定调度目标后，编排工具将根据预定规范管理容器的生命周期。

概括来说，容器编排系统能够为用户提供如下关键能力：

- **集群管理与基础设施抽象**

  > 将多个虚拟机或物理机构建成协同运行的集群，并将这些硬件基础设施抽象为一个统一的资源池。

- **资源分配和优化**

  > 基于配置清单中指定的资源需求与现实可用的资源量，利用成熟的调度算法合理调度工作负载。

- **应用部署**

  > 支持跨主机自动部署容器化应用，支持多版本并存、滚动更新和回滚等机制。
  
- **应用伸缩**

  > 支持应用实例规模的自动或手动伸缩。

- **应用隔离**

  > 支持为租户、项目或应用进行访问隔离。

- **服务可用性**

  > 利用状态监测和应用重构等机制确保服务始终健康运行。

Kubernetes、Mesos和Docker Swarm一度作为竞争对手在容器编排领域三分天下，但这一切在2017年发生了根本性的变化，因为在这一年发生了几个在容器生态发展史上具有里程碑式意义的重要事件：

> 一是 AWS 、Azure 和 Alibaba Cloud都相继在其原有容器服务上新增了对Kubernetes的支持，甚至 Docker 官方也在2017年 10 月宣布同时支持 Swarm 和 Kubernetes 编排系统。
>
> 二是 rkt 容器派系的 CoreOS 舍弃掉自己的调度工具 Fleet ，将商用平台 Tectonic 的重心转移至 Kubernetes。
>
> 三是 Mesos也于2017年9月宣布了对Kubernetes的支持，其平台用户可以安装、扩展和升级多个生产级的 Kubernetes 集群。
>
> 四是 Rancher Labs 推出了2.0版本的容器管理平台并宣布将全部业务集中于 Kubernetes，放弃了其多年内置的容器编排系统 Cattle。这种局面显然意味着 Kubernetes 已经成为容器编排领域事实上的标准。后来，Twitter、CNCF、阿里巴巴、微软、思科等公司与组织纷纷支持 Kubernetes。


以上种种迹象表明，Kubernetes已成为广受认可的基础设施领域工业标准，其近两三年的发展状态也不断验证着 Urs Hölzle曾 经的断言：无论是公有云、私有云抑或混合云，Kubernetes 将作为一个为任何应用、任何环境提供容器管理的框架而无处不在。

## 1.2　Kubernetes基础

微服务的出现与发展促进了容器化技术的广泛应用，以 Docker 为代表的容器技术定义了新的标准化交付方式，而以Kubernetes 为代表的容器编排系统则为规模化、容器化的微服务应用的落地提供了坚实基础和根本保障。Kubernetes是一种可自动实施 Linux 容器编排的开源平台，支持在物理机和虚拟机集群上调度和运行容器，为用户提供了一个极为便捷、有效的容器管理平台，可帮助用户省去应用容器化过程中许多需要手动进行的部署和扩展操作。

Kubernetes（希腊语，意为“舵手”或“飞行员”）又称 k8s，或者简称为 kube ，由Joe Beda、Brendan Burns 和 Craig McLuckie 创立，而后 Google 的其他几位工程师（包括Brian Grant和Tim Hockin等）加盟共同研发，并由 Google 在 2014 年首次对外发布。Google 是最早研发 Linux 容器技术的企业之一（创建CGroups），目前，Google 每周会基于内部平台 Borg 启用超过20亿个容器，而 Kubernetes 的研发和设计都深受该内部平台的影响，事实上，Kubernetes 的许多顶级贡献者之前也是 Borg 系统的开发者。

### 1.2.1　Kubernetes集群概述

Kubernetes 是一个跨多主机的容器编排平台，它使用共享网络将多个主机（物理服务器或虚拟机）构建成统一的集群。其中，一个或少量几个主机运行为 Master（主节点），作为控制中心负责管理整个集群系统，余下的所有主机运行为Worker Node（工作节点），这些工作节点使用本地和外部资源接收请求并以 Pod（容器集）形式运行工作负载。

**图1-6为Kubernetes集群工作模式示意图。**

<img src="C:\Users\admin\Documents\devops\Linux-Basics\k8s\k8s基础\._images\Kubernetes 系统基础\1-6Kubernetes集群.jpg" style="zoom:80%;" />

- Master Node

  > Master 是集群的网关和中枢，负责诸如为用户和客户端暴露API、确保各资源对象不断地逼近或符合用户期望的状态、以最优方式调度工作负载，以及编排其他组件之间的通信等任务，它是各类客户端访问集群的唯一入口，肩负 Kubernetes 系统上大多数集中式管控逻辑。单个 Master 节点即可完成其所有功能，但出于冗余及负载均衡等目的，生产环境中通常需要协同部署多个此类主机。Master 节点类似于蜂群中的蜂王。

- Worker Node（以下简称Node）

  > Worker Node 负责接收来自 Master 的工作指令并相应创建或销毁 Pod 对象，以及调整网络规则以合理完成路由和转发流量等任务，是 Kubernetes 集群的工作节点。理论上讲，Node可以是任何形式的计算设备，负责提供 CPU、内存和存储等计算和存储资源，不过 Master 会统一将其抽象为 Node 对象进行管理。Node 类似于蜂群中的工蜂，在生产环境中，通常数量众多。

概括来说，Kubernetes 将所有工作节点的资源集结在一起形成一台更加强大的“服务器”，其计算和存储接口通过Master 之上的 API 服务暴露，再由 Master 通过调度算法将客户端通过 API 提交的工作负载运行请求自动指派至某特定的工作节点以 Pod 对象的形式运行，且 Master 会自动处理因工作节点的添加、故障或移除等变动对 Pod 的影响，用户无须关心其应用究竟运行于何处。

由此可见，Kubernetes 程序自身更像是构建在底层主机组成的集群之上的“云操作系统”或“云原生应用操作系统”，而容器是运行其上的进程，但 Kubernetes 要通过更高级的抽象 Pod 来运行容器，以便于处理那些具有“超亲密”关系的容器化进程，这些进程必须运行于底层的同一主机之上。因此，Pod 类似于单机操作系统上的“进程组”，它包含一到多个容器，却是 Kubernetes 上的最小调度单元，因而同一 Pod 内的容器必须运行于同一工作节点之上，

**Kubernetes Pod 如图1-7所示。**

![](C:\Users\admin\Documents\devops\Linux-Basics\k8s\k8s基础\._images\Kubernetes 系统基础\1-7Kubernetes Pod.jpg)

不过，Kubernetes 的功能并不限于简单的容器调度，其本质是“以应用为中心”的现代应用基础设施，它通过管理各种基础支撑类服务（例如消息队列、集群存储系统、服务发现、数据处理框架以及负载均衡器等）将各种传统中间件“下沉”至自身内部，并经由声明式 API 向上层应用暴露这些基础设施能力。Kubernetes 实际上是一个 Platform for Platform 类型的项目，其根本目的在于方便基础设施工程师（或称为“容器团队”等）构建其他的平台系统，例如 Service Mesh、PaaS 或 Serverless 等。

有了这种声明式基础设施的支撑，在开发基于Kubernetes的云原生应用时，程序员可更好地集中精力于应用程序的业务本身而无须为程序中需要集成基础设施的能力而困扰。在运行应用时，用户也只需要通过 API 声明应用程序的终态，例如为 Nginx 应用运行6个实例、为 myapp 实例执行滚动更新等，Kubernetes 自己便能完成后续的所有任务，包括确保应用本身的运行终态以及应用所依赖的所有底层基础设施能力的终态，比如路由策略、访问策略和存储需求等。

> 提示：声明式（declarative）编程和命令式（imperative）编程是两种相对的高级编程概念：前者着重于最终结果，如何达成结果则要依赖于给定语言的基础组件能力，程序员只需要指定做什么而非如何去做；后者称为过程式编程更合适，它需要由程序员指定做事情的具体步骤，更注重如何达成结果的过程。声明式编程常用于数据库和配置管理软件中，关系型数据库的 SQL 语言便是最典型的代表之一，而 Kubernetes 中声明式 API 的核心依赖是控制器组件。

Kubernetes在其 RESTful 风格的 API 中以资源形式抽象出多种概念以描述应用程序及其周边组件，这些程序及组件被统称为 API 对象，它们有特定的类型，例如 Node、Namespace、Pod、Service 和 Deployment 等。每个 API 对象都使用“名称”作为其唯一标识符，出于名称隔离与复用以及资源隔离的目的， Kubernetes 使用“名称空间”为名称提供了作用域，并将大多数资源类型归属到名称空间级别。

运行应用的请求需要以配置清单（manifest）格式提交给 Kubernetes API 进行，大多数资源对象包含元数据（例如标签和注释）、所需状态（也称为期望状态或终态）和观察状态（也称为当前状态）等信息。Kubernetes 支持 JSON 或 YAML 编码的配置清单，由API服务器通过 HTTP/HTTPS 协议接收配置清单并存储于 etcd 中，查询请求的结果也将以JSON 序列化格式返回，同时支持更高效的 Protobuf 格式。下面是用于描述API对象的常用配置清单的框架，其意义将在后面的章节予以介绍。

```bash
apiVersion: …    # 资源对象所属的API群组及版本
kind: …          # 资源类型
metadata:        # 资源对象的原数据
…
spec:            # 所需状态
…
```

上述配置清单是基于 Kubernetes API 声明式编程接口的配置代码，读者需要掌握 API 资源类型的定义格式与使用方式后才能灵活使用，难度系数较高。为了平缓初学者的入门曲线，Kubernetes 也支持在命令行工具 kubectl 中以命令式语句提交运行请求。

### 1.2.2　Kubernetes集群架构

Kubernetes 属于典型的 Server-Client 形式的二层架构，在程序级别，Master 主要由 API Server（kube-apiserver）、Controller-Manager（kube-controller-manager）和Scheduler（kube-scheduler）这3个组件，以及一个用于集群状态存储的etcd存储服务组成，它们构成整个集群的控制平面；而每个 Node 节点则主要包含 kubelet、kube-proxy及容器运行时（Docker是最为常用的实现）3个组件，它们承载运行各类应用容器。

**各组件如图1-8中的粗体部分组件所示。**

![](C:\Users\admin\Documents\devops\Linux-Basics\k8s\k8s基础\._images\Kubernetes 系统基础\1-8Kubernetes系统组件.jpg)

1. Master组件：

Master组件是集群的“脑力”输出者，它维护有Kubernetes的所有对象记录，负责持续管理对象状态并响应集群中各种资源对象的管理操作，以及确保各资源对象的实际状态与所需状态相匹配。控制平面的各组件支持以单副本形式运行于单一主机，也能够将每个组件以多副本方式同时运行于多个主机上，提高服务可用级别。控制平面各组件及其主要功能如下：

（1）API Server
		API Server 是 Kubernetes 控制平面的前端，支持不同类型应用的生命周期编排，包括部署、缩放和滚动更新等。它还是整个集群的网关接口，由 kube-apiserver 守护程序运行为服务，通过 HTTP/HTTPS 协议将 RESTful API 公开给用户，是发往集群的所有 REST 操作命令的接入点，用于接收、校验以及响应所有的REST请求，并将结果状态持久存储于集群状态存储系统（etcd）中。

（2）集群状态存储
		Kubernetes 集群的所有状态信息都需要持久存储于存储系统 etcd 中。etcd 是由 CoreOS 基于 Raft 协议开发的分布式键值存储，可用于服务发现、共享配置以及一致性保障（如数据库主节点选择、分布式锁等）。显然，在生产环境中应该以 etcd 集群的方式运行以确保其服务可用性，并需要制定周密的备份策略以确保数据安全可靠。
etcd 还为其存储的数据提供了监听（watch）机制，用于监视和推送变更。API Server 是 Kubernetes 集群中唯一能够与etcd 通信的组件，它封装了这种监听机制，并借此同其他各组件高效协同。

（3）控制器管理器
		控制器负责实现用户通过 API Server 提交的终态声明，它通过一系列操作步骤驱动API对象的当前状态逼近或等同于期望状态。Kubernetes 提供了驱动 Node、Pod、Server、Endpoint、ServiceAccount 和 Token 等数十种类型 API 对象的控制器。从逻辑上讲，每个控制器都是一个单独的进程，但是为了降低复杂性，它们被统一编译进单个二进制程序文件kube-controller-manager（即控制器管理器），并以单个进程运行。

（4）调度器
		Kubernetes 系统上的调度是指为 API Server 接收到的每一个 Pod 创建请求，并在集群中为其匹配出一个最佳工作节点。kube-scheduler 是默认调度器程序，它在匹配工作节点时的考量因素包括硬件、软件与策略约束，亲和力与反亲和力规范以及数据的局部性等特征。

2. Node组件：

Node 组件是集群的“体力”输出者，因而一个集群通常会有多个 Node 以提供足够的承载力来运行容器化应用和其他工作负载。每个 Node 会定期向 Master 报告自身的状态变动，并接受 Master 的管理。

（1）kubelet
		kubelet 是 Kubernetes 中最重要的组件之一，是运行于每个 Node 之上的“节点代理”服务，负责接收并执行 Master 发来的指令，以及管理当前 Node 上 Pod 对象的容器等任务。它支持从 API Server 以配置清单形式接收 Pod 资源定义，或者从指定的本地目录中加载静态 Pod 配置清单，并通过容器运行时创建、启动和监视容器。

kubelet 会持续监视当前节点上各 Pod 的健康状态，包括基于用户自定义的探针进行存活状态探测，并在任何 Pod 出现问题时将其重建为新实例。它还内置了一个 HTTP 服务器，监听 TCP 协议的 10248 和 10250 端口：10248 端口通过 /healthz 响应对 kubelet 程序自身的健康状态进行检测；10250 端口用于暴露 kubelet API，以验证、接收并响应 API Server 的通信请求。

（2）容器运行时环境
		Pod是一组容器组成的集合并包含这些容器的管理机制，它并未额外定义进程的边界或其他更多抽象，因此真正负责运行容器的依然是底层的容器运行时。kubelet 通过 CRI（容器运行时接口）可支持多种类型的 OCI 容器运行时，例如docker、containerd、CRI-O、runC、fraki 和 Kata Containers等。

（3）kube-proxy
		kube-proxy 也是需要运行于集群中每个节点之上的服务进程，它把 API Server 上的 Service 资源对象转换为当前节点上的 iptables 或（与）ipvs 规则，这些规则能够将那些发往该 Service 对象 ClusterIP 的流量分发至它后端的 Pod 端点之上。kube-proxy 是 Kubernetes 的核心网络组件，它本质上更像是 Pod 的代理及负载均衡器，负责确保集群中 Node、Service 和 Pod 对象之间的有效通信。

3. 核心附件

附件（add-ons）用于扩展 Kubernetes 的基本功能，它们通常运行于 Kubernetes 集群自身之上，可根据重要程度将其划分为必要和可选两个类别。网络插件是必要附件，管理员需要从众多解决方案中根据需要及项目特性选择，常用的有Flannel、Calico、Canal、Cilium 和 Weave Net 等。KubeDNS 通常也是必要附件之一，而 Web UI（Dashboard）、容器资源监控系统、集群日志系统和 Ingress Controller 等是常用附件。

- CoreDNS

  > Kubernetes使用定制的 DNS 应用程序实现名称解析和服务发现功能，它自 1.11 版本起默认
  >
  > 使用 CoreDNS ——一种灵活、可扩展的 DNS 服务器；之前的版本中用到的是 kube-dns 项目，SkyDNS 则是更早一代的解决方案。

- Dashboard

  > 基于 Web 的用户接口，用于可视化 Kubernetes 集群。Dashboard 可用于获取集群中资源对象的详细信息，例如集群中的 Node、Namespace、Volume、ClusterRole和 Job 等，也可以创建或者修改这些资源对象。

- 容器资源监控系统

  > 监控系统是分布式应用的重要基础设施，Kubernetes 常用的指标监控附件有 Metrics-Server、kube-state-metrics和 Prometheus等。

- 集群日志系统

  > 日志系统是构建可观测分布式应用的另一个关键性基础设施，用于向监控系统的历史事件补充更详细的信息，帮助管理员发现和定位问题；Kubernetes常用的集中式日志系统是由 ElasticSearch、Fluentd 和 Kibana（称之为 EFK）组合提供的整体解决方案。

- Ingress Controller

  > Ingress资源是 Kubernetes 将集群外部 HTTP/HTTPS 流量引入到集群内部专用的资源类型，它仅用于控制流量的规则和配置的集合，其自身并不能进行“流量穿透”，要通过 Ingress 控制器发挥作用；目前，此类的常用项目有 Nginx、Traefik、Envoy、Gloo、kong 及 HAProxy 等。

在这些附件中，CoreDNS、监控系统、日志系统和 Ingress 控制器基础支撑类服务是可由集群管理的基础设施，而Dashboard 则是提高用户效率和体验的可视化工具，类似的项目还有 polaris 和 octant 等。

## 1.3　应用的运行与互联互通











