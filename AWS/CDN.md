### cloudfront 与 cloudflare

例如：

- cloudfront：z233ltoeov3rr.cloudfront.net
- cloudflare:    api.clemente.com

cloudfront 的 cname 为 `api.clemente.com` ，即 cloudflare 中的域名， cloudflare 添加 `api.clemente.com` 进行一级代理，ssl 中双边加密。

添加完成后访问 api.clemente.com/00001.jpg 查看响应头为，即为添加成功。

```
Server:  cloudflare
x-cache: Hit from cloudfront
```



