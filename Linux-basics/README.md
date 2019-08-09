[1]: http://gitbook.zhangjikai.com/bookjson.html
[2]: /images/create_a_new_repository.png
[3]: /images/github_pages_settings.png
[4]: https://github.com/marketplace/travis-ci
[5]: /images/travis_ci_repositories.png
[6]: https://github.com/settings/tokens
[7]: /images/github_presonal_access_tokens.png
[8]: /images/github_presonal_access_tokens_scopes.png
[9]: /images/Travis_CI_Token.png

# Gitbook Template

[![Build Status](https://travis-ci.com/renkeju/gitbook-template.svg?branch=master)](https://travis-ci.com/renkeju/gitbook-template)

## 项目结构

1. 克隆模版并去掉模版中的历史记录

    ```
    git clone https://github.com/renkeju/gitbook-template l2tp-usage-guide
    cd l2tp-usage-guide && rm -rf .git
    ```

2. 修改模版

    * `.travis.yml`

        * recipients: 修改为你个人邮件地址
        * REF: 修改为你的 github 项目地址

    * `book.json`

        修改 gitbook 相应配置，可以参考此文档 [book.json配置文件][1]

    * `SUMMARY.md` 
        
        定义目录结构

    * `CNAME`

        如果你不需要指定自己使用的域名，可以删除这个文件。
        
        如果需要请在 DNS 服务供应商中使用 CNAME 方式将 gitbook.renkeju.com 指向 renkeju.github.com

3. 在 github 上创建新项目

    比如我对新仓库命名为 l2tp-usage-guide

    ![创建一个新的仓库][2]

    把修改好的模版 push 到新的仓库 

    ```
    echo "# l2tp-usage-guide" > README.md
    git init
    git add .
    git commit -m "first commit"
    git remote add origin git@github.com:renkeju/l2tp-usage-guide.git
    git push -u origin master
    ```

## Github Pages

1. 新建 gh-pages 分支:

    ```
    git checkout -b gh-pages
    git push origin gh-pages
    ```

2. 在项目 `Settings` -> `GitHub Pages`开启 Github Pages 服务:


    ![Github Pages 设置][3]

## Travis CI

1. [点击此处][4] 给刚刚在 github 上创建的项目 l2tp-usage-guide 开启 Travis 服务：

    ![Travis CI 仓库][5]

2. 在 [个人设置][6] 里申请 token 让 Travis 有权限修改这个项目：

    ![Github 个人访问令牌领域][8]

    然后选择 repo，点击生成按钮:

    ![Github 个人访问令牌][7]

3. 复制生成的 token，填写在 Travis 的设置-全局变量中，并且取名为 TOKEN:

    ![Travis CI TOKEN][9]
