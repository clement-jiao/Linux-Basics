### httpd 连接 ldap 示例配置

```xaml
#NameVirtualHost *:80
<VirtualHost _default_:80>
    ServerAdmin support@clemente.comorg
    ServerName payment-backend.clemente.comnet
    # ServerAlias  matrixa.clemente.comnet
    DocumentRoot /var/www/payment-backend/latest
    ErrorLog /var/log/httpd/payment-backend.com-error_log
#    CustomLog /var/log/httpd/asomatrix.com-access_log common

    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" BytesIn: %I BytesOut: %O" combined
    LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" BytesIn: %I BytesOut: %O" proxy
    SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
    CustomLog /var/log/httpd/payment-backend.com-access_log combined env=!forwarded
    CustomLog /var/log/httpd/payment-backend.com-access_log proxy env=forwarded

    <Directory /var/www/payment-backend/latest>
        Options -Indexes +FollowSymlinks
        #AllowOverride All
        #Require all granted

        AuthLDAPURL "ldap://172.17.0.1:389/ou=user,dc=clemente,dc=com?uid?sub?(objectClass=*)"
        AuthLDAPBindDN  "cn=admin,dc=clemente,dc=com"
        AuthLDAPBindPassword "密码"

        AuthType Basic
        AuthName "LDAP Protected"
        AuthUserFile /dev/null
        AuthBasicProvider ldap
        # AuthBasicProvider ldap-test
        # Require valid-user
        AuthLDAPGroupAttribute memberUid

        # group  setting
        AuthLDAPGroupAttributeIsDN on
        AuthLDAPMaxSubGroupDepth 0
        AuthLDAPSubGroupAttribute member
        AuthLDAPSubGroupClass group
        Require ldap-user clemente asd qwe

    </Directory>
</VirtualHost>
```