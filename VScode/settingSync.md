#Settings Sync插件教程

搬运地址：[vs-code-多设备插件同步插件Settings Sync](https://www.jianshu.com/p/cfd7dbb5565d)

>插件名称：Settings Sync
插件地址：https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync
插件说明：多个设备来回安装vscode插件及快捷键配置很麻烦，用这个插件就可以通过配置文件的形式在多个设备之间同步vscode的配置了

##安装步骤
1. mac版 vs-code里面 extensions 拓展插件打开，搜索 Settings Sync 安装
2. 打开并登录 [github.com](https://github.com/settings/tokens) ，页面左下角找到并点击 【Personal access tokens】
3. 页面又上角 找到并点击 【Generate new token】
4. description 输入名称 【code_sync】CheckBox 选中【 gist  Create gists 】，点击 绿色button【Generate token】，页面上会出现绿底色的tokens，复制粘贴到剪切板或保留页面不要关闭
5. 切换到 vscode，，随便找到一个页面，alt+shift+u，窗口顶部出现一个小提示，让输入 刚才绿底色的tokens，把剪切板里面的内容粘贴，return
6. 会自动打开一个syncSummary.txt的文件，证明你已经同步成功。
7. 打开 [gist.github.com](https://gist.github.com/)  会出现一个cloudsettings的文件，里面就是你刚同步上去的配置文件
8. 如果tokens在vscode里面输入错了，就按 F1，输入 【 sync 】，reset 即可。

