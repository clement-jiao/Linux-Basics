<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2020-06-05 00:24:59
 * @LastEditors: clement-jiao
 * @LastEditTime: 2021-06-20 01:04:11
-->

### sourcetree安装跳过注册方法

今天安装sourcetree一直卡在注册界面，注册并登陆成功后，也无法继续安装

1、地址栏直接输入 %LocalAppData%\Atlassian，接着进入SourceTree目录，创建accounts.json文件，并复制以下代码至accounts.json：
```json
[
  {
    "$id": "1",
    "$type": "SourceTree.Api.Host.Identity.Model.IdentityAccount, SourceTree.Api.Host.Identity",
    "Authenticate": true,
    "HostInstance": {
      "$id": "2",
      "$type": "SourceTree.Host.Atlassianaccount.AtlassianAccountInstance, SourceTree.Host.AtlassianAccount",
      "Host": {
        "$id": "3",
        "$type": "SourceTree.Host.Atlassianaccount.AtlassianAccountHost, SourceTree.Host.AtlassianAccount",
        "Id": "atlassian account"
      },
      "BaseUrl": "https://id.atlassian.com/"
    },
    "Credentials": {
      "$id": "4",
      "$type": "SourceTree.Model.BasicAuthCredentials, SourceTree.Api.Account",
      "Username": "",
      "Email": null
    },
    "IsDefault": false
  }
]
```
2、然后打开SourceTree.exe_Url_ul4qrk3hz4zqb14vcaiypmrdv255kkqk\3.3.8.3848\下的user.config文件（不同版本路径有所不同，我的是3.3.8版本），增加如下代码：
```xml
  <setting name="AgreedToEULA" serializeAs="String">
      <value>True</value>
  </setting>
  <setting name="AgreedToEULAVersion" serializeAs="String">
      <value>20160201</value>
  </setting>
```

3、重新点击SourceTree.exe安装，弹出 Mercurial 窗口时，选择最后一项安装即可。


### 删除已经提交到远程的commit
#### 首先是重置到上一次commit
右键需要回滚的分支：**选择重置当前分支到此次提交**
#### 然后打开终端:
使用 `git push origin -f` 命令 使本次提交为强制 push


(三种清除Git提交历史的方法)[https://blog.csdn.net/yiifaa/article/details/78603410]
