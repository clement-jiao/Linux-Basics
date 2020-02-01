### Roles 各目录作用
/roles/project/：项目名称，有以下子目录
  - files/：存放由 copy 或 script 模块等调用的文件
  - templates/：template 模块查找所需要模板文件的目录
  - tasks/：定义 task,role 的基本元素；至少应该包含一个名为 main.yaml 的文件；其他的文件需要在此文件中通过 include 进行包含
  - handles/：task内任务触发器；至少应该包含一个名为 main.yaml 的文件；其他的文件需要在此文件中通过 include 进行包含
  - vars/：定义变量；至少应该包含一个名为 main.yaml 的文件；其他的文件需要在此文件中通过 include 进行包含
  - meta/：定义当前角色的特殊设定及其依赖关系，至少应该包含一个名为 main.yaml 的文件；其他的文件需要在此文件中通过 include 进行包含
  - default/：设定默认变量时使用此目录中的 main.yaml 文件
