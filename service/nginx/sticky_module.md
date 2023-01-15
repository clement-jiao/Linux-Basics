## nginx 会话保持 sticky 模块


[rpm@k8smaster01 srcsoft]$ sh install-nginx.sh >11.txt 
You need to be root to perform this command.
ar: creating ../libcrypto.a
ar: creating ../libssl.a
WARNING: can't open config file: /data/soft/nginx-1.11.10/module/openssl-1.0.2j/.openssl/ssl/openssl.cnf
WARNING: can't open config file: /data/soft/nginx-1.11.10/module/openssl-1.0.2j/.openssl/ssl/openssl.cnf
WARNING: can't open config file: /data/soft/nginx-1.11.10/module/openssl-1.0.2j/.openssl/ssl/openssl.cnf
WARNING: can't open config file: /data/soft/nginx-1.11.10/module/openssl-1.0.2j/.openssl/ssl/openssl.cnf
/data/soft/nginx-1.11.10/module/nginx-sticky-module-1.2.6/ngx_http_sticky_misc.c: In function ‘ngx_http_sticky_misc_md5’:
/data/soft/nginx-1.11.10/module/nginx-sticky-module-1.2.6/ngx_http_sticky_misc.c:152:15: error: ‘MD5_DIGEST_LENGTH’ undeclared (first use in this function)
   u_char hash[MD5_DIGEST_LENGTH];
               ^
/data/soft/nginx-1.11.10/module/nginx-sticky-module-1.2.6/ngx_http_sticky_misc.c:152:15: note: each undeclared identifier is reported only once for each function it appears in
/data/soft/nginx-1.11.10/module/nginx-sticky-module-1.2.6/ngx_http_sticky_misc.c:152:10: error: unused variable ‘hash’ [-Werror=unused-variable]
   u_char hash[MD5_DIGEST_LENGTH];
          ^
/data/soft/nginx-1.11.10/module/nginx-sticky-module-1.2.6/ngx_http_sticky_misc.c: In function ‘ngx_http_sticky_misc_hmac_md5’:
/data/soft/nginx-1.11.10/module/nginx-sticky-module-1.2.6/ngx_http_sticky_misc.c:189:15: error: ‘MD5_DIGEST_LENGTH’ undeclared (first use in this function)
   u_char hash[MD5_DIGEST_LENGTH];
               ^
/data/soft/nginx-1.11.10/module/nginx-sticky-module-1.2.6/ngx_http_sticky_misc.c:190:12: error: ‘MD5_CBLOCK’ undeclared (first use in this function)
   u_char k[MD5_CBLOCK];

解决方式：
修改sticky模块文件夹中的ngx_http_sticky_misc.c文件

将这两个模块 <openssl/sha.h> and <openssl/md5.h>包含到文件ngx_http_sticky_misc.c
下面标注的地方
```c
// vim ngx_http_sticky_misc.c
#include <nginx.h>
#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>
#include <ngx_md5.h>
#include <ngx_sha1.h>
// 添加
#include <openssl/sha.h>
#include <openssl/md5.h>
// 结束
#include "ngx_http_sticky_misc.h"
..
```

之后再重新编译就不会出错了

### 安装参考资料
https://www.cnblogs.com/tssc/p/7481885.html
使用方法
http://t.zoukankan.com/liyongsan-p-8494445.html