### 一、Pipline job 优点
Jenkins 1.X 只能通过界面手动操作来“描述”部署流水线。Jenkins 2.X 支持 pipline as code了，可以通过groovy语言类描述部署流水线。
使用groovy语言而不是UI界面的意义在于:
1. 版本化：Pipline  以代码的形式实现,通常被检入源代码控制，使得团队能够编辑、审查和迭代期CD流程。
2. 可持续：Jenkins  重启或中断后都不会影响 Pipeline job，方便 Job 配置迁移与版本控制。
3. 可停顿：Pipeline 可以选择停止并等待输入或批准，然后再继续 Pipeline 运行。
4. 多功能：Pipeline 可以支持现实世界的复杂CD要求，包括 fork/join 子进程，循环和并行执行工作的能力
5. 可扩展：Pipeline 插件支持其DSL的自定义扩展以及与其他插件集成的多个选项。

Jenkins Pipeline 的定义通常被写入到一个文本文件里(称为Jenkinsfile)，该文件可以被放入项目的源代码控制库中。
Jenkinsfile 不一定叫 Jenkinsfile，可以在源代码中定义。

### 二、基础语法
```groovy
pipeline{
  agent any
  stages {
    stage('build'){
      steps {
        echo 'hello word!'
      }
    }
  }
}
```
### 三、pipeline 总体介绍
1.pipeline的组成
基本结构：
以下每个部分都是必须项，少一个都会报错。
```groovy
// 代表整条流水线，包含整条流水线的逻辑
pipeline{
  // 制定流水线的执行位置,流水线中每个阶段都必须在某个地方执行(物理机/虚拟机/docker容器),agent部分指定具体在哪执行
  agent {
    node {
      label 'master'
    }
  }
  // stages: 流水线中多个stage的容器, stage部分至少包含一个stage
  stages {
    // 阶段: 代表流水线的阶段,每个阶段都必须有名称
    stage('build'){
      steps {
        echo 'hello word!'
      }
    }
  }
}
```
其他可选结构:
post:包含的是在整个pipeline 或stage完成后的附加步骤
  always: 无论pipeline运行的完成状态如何,都会执行这段代码
  change: 只有当前Pipeline运行的状态与先前完成的Pieline的状态不同时,才能触发运行.
  failure: 当前完成状态为失败时执行
  success: 当前完成状态为成功时执行
示例:
```groovy
post {
  always {
    script {
      allure includeProperties: false, jdk: '', report: 'jenkins-allure-report', results: [[path: 'allure-results']]
    }
  }
  failure {
    script {
      if (gitpullerr == 'noerr') {
        mail to : "${email_list}",
            subject: "[Jenkins Build Notification] ${JOB_NAME} - Build # ${BUILD_NUMBER} -构建失败!"
            body: "'${env.JOB_NAME}' (${env.BUILD_NUMBER}) 执行失败了 \n请及时前往 ${env.BUILD_URL} 进行查看"
      }else {
        echo 'scm pull error ignore send mail'
      }
    }
  }
}
```
pipeline 支持的指令:
- environment: 用于设置环境变量,可定义在stage或pipeline部分,环境变量可以像下面的示例设置为全局的,也可以是阶段(stage)级别的.如你所想,阶段(stage)级别的环境变量只能在定义变量的阶段(stage)使用.
- tools: 可定义在pipeline或stage部分,会自动下载并安装我们指定的工具,并将其加入到PATH变量中
- input: 定义在stage部分,会暂停pipeline, 提示你输入内容.
- options: 用于配置jenkins pipeline 本身的选项, options 指令可以定义在stage或pipeline部分.
- parallel: 并行执行多个 step
- parameters: 与input不同, parameters是执行pipeline前传入的一些参数.
- triggers: 定义执行 pipeline的触发器
- when: 当满足when条件时,阶段才会执行.
>在使用指令时注意每隔指令都有自己的作用域,如果指令使用的位置不正确,jenkins会报错

2.变量定义(全局)
通过 def project_name,定义job名称
通过 def upstream_list= 'qianji-common, AppQianjiUserPortraitService'
- 定义上游job名称,用在触发器里

3.options
用于配置整个pipeline 本身的选项
```groovy
options{
  buildDiscarder(logRotator(numToKeepStr:'30'))
  timeout(time: 1, unit: 'HOURS')
  disableConcurrentBuilds()
}
```
buildDiscarder: 保存最近历史构建记录的数量
disableConcurrentBuilds: 同一个pipeline,jenkins 是默认可以同时执行多次的,此选项是为了禁止pipeline同时执行retry: 当发生失败时进行重试retry(4)

4.parameters
该parameters指令提供用户在处罚pipeline时应提供的参数列表.这些用户指定的参数的值通过该params对象可用于pipeline步骤
```groovy
parameters {
  choice(name: 'environ', choices: 'test\ndev\nstg', description: '测试环境, 请选择dev? test? stg?')
  string(name: 'keywords', defaultValue: ",description:'测试用例名的关键字, 用于过滤测试用例'")
  string(name: 'folder', defaultValue: ",description:'文件夹名称, 用于指定具体跑哪个文件夹下的case'")
}
```
字符串类型的参数:
例如: parameters{string(name: 'DEPLOY_ENV', defaultValue:'staging',description:"")}

booleanParam:
一个布尔参数, 例如: parameters{booleanParam(name:'Debug_Build', defaultValue: true, description:"")}

目前支持 [booleanParam, choice, credentials, file, text password, run, string]这几种参数类型

```groovy
stage('执行测试用例'){
  steps{
    sh "rm -rf $env.WORKSPACE/allure-*"
    sh "pipenv run py.test --env '${params.environ}' -k '${params.keywords}'"
  }
}
```

4.triggers配置
trigger指令定义了流水线被重新触发的自动化方法. 当前可用的触发器是cron,pollSCM,upstream,gitlab
例如:
```groovy
trigger{
  pollSCM('H * * * 1-5')  // 周一到周五, 每小时
  cron('H H * * *') // 每天
  gitlab(triggerOnPush: true, triggerOnMergeRequest: false, branchFilterType: 'All')
  upstream(upstreamProjects: "${upstream_list}", threshold: Hudson.model.Result.SUCCESS)
}
```

定时触发: cron
接收cron样式的字符来定义要重新触发流水线的常规间隔, 比如: cron('H H * * *')  // 每天

轮询代码仓库: pollSCM
接收cron样式的字符来定义一个固定间隔,在这个间隔中, jenkins会检查新的源代码更新.
如果存在更改, 流水线就会被重新触发. 比如: pollSCM('H * * * 1-5')  // 周一到周五, 每小时

由上游任务触发: upstream
接受逗号分隔的工作字符串和阈值. 当字符串中的任何作业以最小阈值结束时,流水线被重新触发.
例如:triggers{upstream(upstreamProject: 'job1, job2', threshold: Hudson.model.Result.SECCESS)}
hudson.model.Result包括以下状态:
aborted: 任务被手动终止
failure: 构建失败
success: 构建成功
unstable:存在一些问题, 单构建没失败




















