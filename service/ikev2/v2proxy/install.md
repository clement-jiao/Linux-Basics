### 自用教程
#### install program
`bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)`
#### install acmesh
`curl  https://get.acme.sh | sh -s email=jiaoguofeng@clement.com`

#### 安装证书
申请ec-384 证书 `acme.sh --issue -d tp4.clemente.com --standalone -k ec-384`

[安装ecc证书说明](https://guide.v2fly.org/advanced/wss_and_web.html#服务器配置)

```bash
# 顺序未测试
acme.sh 
  --ecc \
  --installcert \
  -d tp4.clemente.com	\
  --fullchainpath /root/.acme.sh/tp4.clemente.com_ecc/v2ray.crt \
  --keypath /root/.acme.sh/tp4.clemente.com_ecc/v2ray.key

    # acme.sh --installcert -d tp4.clemente.com --fullchainpath /root/.acme.sh/tp4.clemente.com/v2ray.crt --keypath /root/.acme.sh/tp4.clemente.com/v2ray.key --ecc
```

注意客户端加密算法： chacha20-poly1305

```text
[Tue Sep 28 05:00:20 EDT 2021] Installing key to: /root/.acme.sh/tp4.clemente.com_ecc/v2ray.key
[Tue Sep 28 05:00:20 EDT 2021] Installing full chain to: /root/.acme.sh/tp4.clemente.com_ecc/v2ray.crt
```