### openldap + apache2.4

Apache httpd 服务集成 openLDAP
以下是配置文件内容

```conf
#NameVirtualHost *:80
<VirtualHost _default_:80>
    ServerAdmin support@clement.com
    ServerName web.clement.com
    # ServerAlias  web1.clement.net
    DocumentRoot /var/www/web/latest
    ErrorLog /var/log/httpd/web.clement.com-error_log
#    CustomLog /var/log/httpd/clement.com-access_log common

    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" BytesIn: %I BytesOut: %O" combined
    LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" BytesIn: %I BytesOut: %O" proxy
    SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
    CustomLog /var/log/httpd/web.clement.com-access_log combined env=!forwarded
    CustomLog /var/log/httpd/web.clement.com-access_log proxy env=forwarded

    # <AuthnProviderAlias ldap ldap-test>
    #     AuthLDAPURL "ldap://192.168.1.1:389/ou=users,dc=clement,dc=com?uid?sub?(objectClass=*)"
    #     AuthLDAPBindDN  "cn=admin,dc=clement,dc=com"
    #     AuthLDAPBindPassword "password"
    # </AuthnProviderAlias>
    <Directory /var/www/web/latest>
        Options -Indexes +FollowSymlinks
        #AllowOverride All
        #Require all granted

        # ldap 配置
        AuthLDAPURL "ldap://192.168.1.1:389/ou=users,dc=clement,dc=com?uid?sub?(objectClass=*)"
        AuthLDAPBindDN  "cn=admin,dc=clement,dc=com"
        AuthLDAPBindPassword "password"

        AuthType Basic
        AuthName "LDAP Protected"
        AuthUserFile /dev/null
        AuthBasicProvider ldap                          # 未验证
        # Require valid-user                            # 被注释了
        # Require ldap-group ou=user,dc=clement,dc=cn   # 有效, systemctl reload httpd.service
        AuthLDAPGroupAttribute memberUid
        # 必填项，否则会报(AuthUserFile not specified in the configuration)
        # https://stackoverflow.com/questions/15216818/authuserfile-not-specified-in-the-configuration-error
        # AuthBasicProvider ldap-test                   # 未验证，（需要结合 <AuthnProviderAlias> 但他是无效的）
        # AuthLDAPGroupAttributeIsDN off                # 未验证

        # group  setting
        AuthLDAPGroupAttributeIsDN on
        AuthLDAPMaxSubGroupDepth 0
        AuthLDAPSubGroupAttribute member
        AuthLDAPSubGroupClass group
        Require ldap-user clement tester dalao

    </Directory>
</VirtualHost>
```
