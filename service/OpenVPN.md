<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-22 20:22:27
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-22 21:30:16
 -->
#OpenVPN 在 centOS 7 下安装

##相关依赖安装
  - 环境就是新装 CentOS7.5，使用tuna的epel源和常规源。
    ```bash
    [root@localhost ~]# yum -y install openvpn easy-rsa tree
    ```

##配置 EasyRSA-3.0
  - 复制 EasyRSA 3.0.3
    ```bash
    [root@vpn_test easy-rsa]# ll
    total 0
    lrwxrwxrwx 1 root root  5 Aug 22 18:48 3 -> 3.0.3
    lrwxrwxrwx 1 root root  5 Aug 22 18:48 3.0 -> 3.0.3
    drwxr-xr-x 3 root root 62 Aug 22 18:48 3.0.3
    [root@vpn_test easy-rsa]# pwd
    /usr/share/easy-rsa
    ```

  - 复制 EasyRSA 到 OpenVPN 目录下
    ```bash
    [root@localhost ~]# cp -r /usr/share/easy-rsa/3.0.3/ /etc/openvpn/easyServer
    [root@localhost ~]# cd /etc/openvpn/easy-rsa/

    # 复制 vars 模板 或者在 /usr/share/doc/easy-rsa-3.0.3/ 下也能找到
    [root@localhost 3.0.3]# find / -type f -name "vars.example" | xargs -i cp {} . && mv vars.example vars
    ```

  - 创建一个新的PKI和CA
    ```bash
    [root@localhost 3.0.3]# pwd
    /etc/openvpn/easyrsa
    [root@localhost 3.0.3]# ./easyrsa init-pki              #创建空的pki

    Note: using Easy-RSA configuration from: ./vars

    init-pki complete; you may now create a CA or requests.
    Your newly created PKI dir is: /etc/openvpn/easy-rsa/3.0.3/pki


    [root@vpn_test easyServer3]# ./easyrsa build-ca nopass  # nopass 不使用密码

    Note: using Easy-RSA configuration from: ./vars
    Generating a 2048 bit RSA private key
    .+++
    .............................................................+++
    writing new private key to '/etc/openvpn/server/easyServer3/pki/private/ca.key.doHEiRurku'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Common Name (eg: your user, host, or server name) [Easy-RSA CA]:

    CA creation complete and you may now import and sign cert requests.
    Your new CA certificate file for publishing is at:
    /etc/openvpn/server/easyServer3/pki/ca.crt
    ```

  - 创建服务端证书

    ```bash
    [root@vpn_test easyServer3]# ./easyrsa gen-req vpn_test nopass            # 创建服务端文件名为 vpn_test

    Note: using Easy-RSA configuration from: ./vars
    Generating a 2048 bit RSA private key
    .........................................+++
    ..+++
    writing new private key to '/etc/openvpn/server/easyServer3/pki/private/vpn_test.key.4piP5f1Uzg'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Common Name (eg: your user, host, or server name) [vpn_test]:             # 回车

    Keypair and certificate request completed. Your files are:
    req: /etc/openvpn/server/easyServer3/pki/reqs/vpn_test.req
    key: /etc/openvpn/server/easyServer3/pki/private/vpn_test.key
    ```

  - 签约服务端证书
    ```bash
    [root@vpn_test easyServer3]# ./easyrsa sign server vpn_test               # 刚才的服务端名称

    Note: using Easy-RSA configuration from: ./vars


    You are about to sign the following certificate.
    Please check over the details shown below for accuracy. Note that this request
    has not been cryptographically verified. Please be sure it came from a trusted
    source or that you have verified the request checksum with the sender.

    Request subject, to be signed as a server certificate for 3650 days:

    subject=
        commonName                = vpn_test


    Type the word 'yes' to continue, or any other input to abort.
      Confirm request details: yes                                            # 输入 yes 继续，按其他键中断
    Using configuration from ./openssl-1.0.cnf
    Check that the request matches the signature
    Signature ok
    The Subject is Distinguished Name is as follows
    commonName            :ASN.1 12:'vpn_test'
    Certificate is to be certified until Aug 19 11:19:06 2029 GMT (3650 days)

    Write out database with 1 new entries
    Data Base Updated

    Certificate created at: /etc/openvpn/server/easyServer3/pki/issued/vpn_test.crt
    ```

  - 创建 Diffie-Hellman
    ```bash
    [root@vpn_test easyServer3]# ./easyrsa gen-dh

    Note: using Easy-RSA configuration from: ./vars
    Generating DH parameters, 2048 bit long safe prime, generator 2
    This is going to take a long time
    ...................+'2048位秘钥大概需要两三分钟时间'............................................

    DH parameters of size 2048 created at /etc/openvpn/server/easyServer3/pki/dh.pem
    ```
    >到这里服务端的证书就创建完了，然后创建客户端的证书

##创建客户端证书
  - 复制 EasyRSA 文件
    ```bash
    [root@localhost ~]# cp -r /usr/share/easy-rsa/3.0.3/ /etc/openvpn/easyServer
    [root@localhost ~]# cd /etc/openvpn/easy-rsa/

    # 复制 vars 模板 或者在 /usr/share/doc/easy-rsa-3.0.3/ 下也能找到
    [root@localhost 3.0.3]# find / -type f -name "vars.example" | xargs -i cp {} . && mv vars.example vars
    ```

  - 生成证书
    ```bash
    [root@vpn_test easyClient]# ./easyrsa init-pki

    Note: using Easy-RSA configuration from: ./vars

    init-pki complete; you may now create a CA or requests.
    Your newly created PKI dir is: /etc/openvpn/client/easyClient/pki



    [root@vpn_test easyClient]# ./easyrsa gen-req jiaoguofeng nopass

    Note: using Easy-RSA configuration from: ./vars
    Generating a 2048 bit RSA private key
    ..............................................................+++
    ............+++
    writing new private key to '/etc/openvpn/client/easyClient/pki/private/jiaoguofeng.key.xvYMP9NEdb'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Common Name (eg: your user, host, or server name) [jiaoguofeng]:

    Keypair and certificate request completed. Your files are:
    req: /etc/openvpn/client/easyClient/pki/reqs/jiaoguofeng.req
    key: /etc/openvpn/client/easyClient/pki/private/jiaoguofeng.key
    ```

  - 最后签约客户端证书
    ```bash
    [root@vpn_test easyClient]# cd ../../easyrsa/         # 切换到服务端
    [root@vpn_test easyrsa]# pwd
    /etc/openvpn/easyrsa                                  # 在服务端签发客户端证书
    [root@vpn_test easyrsa]# ./easyrsa import-req ../client/easyClient/pki/reqs/jiaoguofeng.req jiaoguofeng

    Note: using Easy-RSA configuration from: ./vars

    The request has been successfully imported with a short name of: jiaoguofeng
    You may now use this name to perform signing operations on this request.

    [root@vpn_test easyrsa]# ./easyrsa sign client jiaoguofeng

    Note: using Easy-RSA configuration from: ./vars


    You are about to sign the following certificate.
    Please check over the details shown below for accuracy. Note that this request
    has not been cryptographically verified. Please be sure it came from a trusted
    source or that you have verified the request checksum with the sender.

    Request subject, to be signed as a client certificate for 3650 days:

    subject=
        commonName                = jiaoguofeng


    Type the word 'yes' to continue, or any other input to abort.
      Confirm request details: yes
    Using configuration from ./openssl-1.0.cnf
    Check that the request matches the signature
    Signature ok
    The Subject is Distinguished Name is as follows
    commonName            :ASN.1 12:'jiaoguofeng'
    Certificate is to be certified until Aug 19 11:37:52 2029 GMT (3650 days)

    Write out database with 1 new entries
    Data Base Updated

    Certificate created at: /etc/openvpn/easyrsa/pki/issued/jiaoguofeng.crt
    ```

  - 整理证书
    > 刚才已经生成完所有需要的证书，现在整理一下

  - 服务端所需要的文件
    ```bash
    [root@localhost ~]# mkdir /etc/openvpn/certs
    [root@localhost ~]# cd /etc/openvpn/certs/
    [root@localhost certs]# cp /etc/openvpn/easy-rsa/pki/dh.pem ./
    [root@localhost certs]# cp /etc/openvpn/easy-rsa/pki/ca.crt ./
    [root@localhost certs]# cp /etc/openvpn/easy-rsa/pki/issued/server.crt ./
    [root@localhost certs]# cp /etc/openvpn/easy-rsa/pki/private/server.key ./
    [root@localhost certs]# ll
    总用量 20
    -rw-------. 1 root root 1172 4月  11 10:02 ca.crt
    -rw-------. 1 root root  424 4月  11 10:03 dh.pem
    -rw-------. 1 root root 4547 4月  11 10:03 server.crt
    -rw-------. 1 root root 1704 4月  11 10:02 server.key
    ```
  - 客户端所需的文件
    ```bash
    [root@localhost certs]# mkdir /etc/openvpn/client/jiaoguofeng/
    [root@localhost certs]# cp /etc/openvpn/easyClient/pki/ca.crt /etc/openvpn/client/jiaoguofeng/
    [root@localhost certs]# cp /etc/openvpn/easyClient/pki/issued/jiaoguofeng.crt /etc/openvpn/client/jiaoguofeng/
    [root@localhost certs]# cp /etc/openvpn/client/easyClient/pki/private/jiaoguofeng.key /etc/openvpn/client/jiaoguofeng/
    [root@localhost certs]# ll /etc/openvpn/client/jiaoguofeng/
    总用量 16
    -rw-------. 1 root root 1172 4月  11 10:07 ca.crt
    -rw-------. 1 root root 4431 4月  11 10:08 jiaoguofeng.crt
    -rw-------. 1 root root 1704 4月  11 10:08 jiaoguofeng.key
    ```

    >添加用户在./easyrsa gen-req 这里开始就行了，像是吊销用户证书的命令都自己用 ./easyrsa --help 去看吧，[GitHub](https://github.com/OpenVPN/easy-rsa/blob/v3.0.5/README.quickstart.md) 项目地址。

  - 服务器配置文件
    ```conf
    [root@vpn_test easyrsa]# egrep -v "(^$|#|;)" ../server.conf

    local 211.155.95.246
    port 1194
    proto udp
    dev tun
    ca /etc/openvpn/certs/ca.crt
    cert /etc/openvpn/certs/vpn_test.crt
    dh /etc/openvpn/certs/dh.pem
    server 10.8.0.0 255.255.255.0
    ifconfig-pool-persist ipp.txt
    client-to-client
    keepalive 10 120
    cipher AES-256-CBC
    comp-lzo
    user openvpn
    group openvpn
    persist-key
    persist-tun
    status openvpn-status.log
    log         openvpn.log
    log-append  openvpn.log
    verb 3
    explicit-exit-notify 1
    ```

  - 启动服务
    ```bash
    [root@localhost ~]# systemctl start openvpn@server
    ```

##配置 iptables 及转发
  - 关闭 firewall
    ```bash
    [root@openvpn ~]# systemctl stop firewalld.service    //停止服务
    [root@openvpn ~]# systemctl disable firewalld.service //禁止开启动
    [root@openvpn ~]# firewall-cmd --state                //查看状态
    ```

  - 安装 iptables，写入策略(按自己需要来写)
    ```bash
    [root@openvpn ~]# yum -y install iptables iptables-services
    [root@openvpn ~]# iptables -t nat -A POSTROUTING -s 17.166.221.0/24 -o ens192 -j MASQUERADE   #NAT
    [root@openvpn ~]# systemctl enable iptables.service
    Created symlink from /etc/systemd/system/basic.target.wants/iptables.service to /usr/lib/systemd/system/iptables.service.
    [root@openvpn ~]# systemctl start iptables.service
    [root@openvpn ~]# iptables -L -n
    [root@openvpn ~]# iptables -t nat -L -n
    ```
    >上面的操作只是单纯的添加了一个 nat，端口没做任何限制，全部开放。
    >如果你的服务器 iptables 已经装好了，而且还有一系列的规则，你的操作就是放行 vpn 端口，添加 NAT，以上两项完成之后看一下现有的规则，看 FORWARD 链，如果发现这一个，就还需要添加 FORWARD 规则
    ```bash
    Chain FORWARD (policy ACCEPT)
    target     prot opt source               destination
    REJECT     all  --  0.0.0.0/0            0.0.0.0/0            reject-with icmp-host-prohibited
    ```

##关于吊销证书

正常情况下证书就是一人一个，下面栗子，注销名为 dalin 的证书。

  ```bash
  [root@openvpn ~]# cd /etc/openvpn/easy-rsa/
  [root@openvpn easy-rsa]# ./easyrsa revoke dalin

  Note: using Easy-RSA configuration from: ./vars


  Please confirm you wish to revoke the certificate with the following subject:

  subject=
      commonName                = dalin


  Type the word 'yes' to continue, or any other input to abort.
    Continue with revocation: yes
  Using configuration from /etc/openvpn/easy-rsa/openssl-1.0.cnf
  Revoking Certificate 06.
  Data Base Updated

  IMPORTANT!!!

  Revocation was successful. You must run gen-crl and upload a CRL to your
  infrastructure in order to prevent the revoked cert from being accepted.

  [root@openvpn easy-rsa]# ./easyrsa gen-crl

  Note: using Easy-RSA configuration from: ./vars
  Using configuration from /etc/openvpn/easy-rsa/openssl-1.0.cnf

  An updated CRL has been created.
  CRL file: /etc/openvpn/easy-rsa/pki/crl.pem
  ```
  >执行上述命令后用户证书不会被删除，只是更新了 crl.pem 文件，可以看到上面的提示，文件位置在 /etc/openvpn/easy-rsa/pki/crl.pem，查看所有证书的的信息，可以这样去看。

  ```bash
  [root@openvpn easy-rsa]# find /etc/openvpn/ -type f -name "index.txt" | xargs cat
  V    280825082643Z        01    unknown    /CN=server
  R    280826061455Z    181211135800Z    03    unknown    /CN=dalin
  ```
  >列举了两个作对比，V 为可用，R 为注销，现在 dalin 的证书还是能连接到服务器，现在需要告知服务端 crl.pem 的位置，下面修改配置文件。

  ```bash
  [root@openvpn easy-rsa]# vim /etc/openvpn/server.conf
  crl-verify /etc/openvpn/easy-rsa/pki/crl.pem
  [root@openvpn easy-rsa]# systemctl restart openvpn@server
  ```
  >这样就可以了，dalin 现在就无法连接到服务器了，服务端日志。

  ```bash
  [root@openvpn easy-rsa]# cd /etc/openvpn/
  [root@openvpn openvpn]# find . -type f -name "dalin.*" | xargs rm
  ```
  >效果达到了，我还得重新生成一下，因为我要用，当然还叫 dalin，这种情况建议将被吊销的证书删掉之后再生成新的。
