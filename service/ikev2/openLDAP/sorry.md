### openLDAP
关于 ldap 着实没什么可说的，用户权限研究快一周也没明白是要改哪里，改数据库虽然提示成功但是在后面测试时并没有什么效果。

为了不交白卷（毕竟研究了快一个月的鬼东西 ！） 所以就在记录下操作方法吧

查询用户

```bash
ldapsearch -x -H ldap:/// -b 'ou=cs,dc=clemente,dc=com' -D 'cn=asd,dc=clemente,dc=com' -W
# -x 简单认证 ，-W 输入密码，-w 指定密码
# -b 查询的 DN ，-D 通过哪个用户查询。
```

修改配置

```bash
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f acl.ldif
```



完。 emmm，这个字很贴切。



附上一个 acl.dlif 文件格式吧，以后少踩点坑

以下内容可以在 `/docker/ldap/conf/cn=config/olcDatabase\=\{1\}mdb.ldif  `中找到，有的人数据库是hdb 也有mdb，不过创建这么多一直都是mdb，不知道那些mdb是不是旧版本的原因。

```dlif
dn: olcDatabase={2}hdb,cn=config	# 入口
changetype: modify								# 由modify写入
replace: olcAccess								# 动作：add/delete/replace
olcAccess: {0}to dn.children="dc=nnlmhpcc" attrs=userPassword,shadowLastChange
  by dn="cn=Manager,dc=nnlmhpcc" manage
  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
  by dn="cn=ldapreader,dc=nnlmhpcc" read
  by self write
  by * auth
olcAccess: {1}to *
  by dn="cn=Manager,dc=nnlmhpcc" manage
  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
  by * read

```







```bash
# 附一下乱七八糟没什么用的东西，说不定以后能帮自己回忆起来些什么






access to dn.chilren="ou=serv,dc=clemente,dc=com"
attrs=userPassword  # 指定“密码”属性 
by self write       # 用户自己可更改 
by * auth           # 所有访问者需要通过认证 
by dn.children="ou=admins,dc=mydomain,dc=org" write #管理员组的用户可更改

access to dn.subtree="ou=SUDOers,dc=clemente,dc=com" #SUDOers的所有内容必须提供其他匿名可读，不然在linux上切换到该用户，不能使用sudo 
by dn="cn=Manager,dc=test,dc=com" write 
by * read 

access to attrs="gidNumber,homeDirectory,loginShell,uidNumber,sshPublicKey" 
by * read #对这些属性只能读，但是userPassword字段是可写的，允许用户自行修改密码，但是不能修改自己的gid，home目录等 


access to dn="ou=group,ou=user,ou=marketer,ou=devops,ou=tester,dc=clemente,dc=com"
by anonymous none
by self read
by dn='ou=serv,dc=clemente,dc=com' read
by dn='cn=admins,dc=clemente,dc=com' write


dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to dn.children="dc=nnlmhpcc" attrs=userPassword,shadowLastChange
  by dn="cn=Manager,dc=nnlmhpcc" manage
  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
  by dn="cn=ldapreader,dc=nnlmhpcc" read
  by self write
  by * auth
olcAccess: {1}to *
  by dn="cn=Manager,dc=nnlmhpcc" manage
  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
  by * read




cat > add_access.ldif <<EOF dn: olcDatabase={1}mdb,cn=config changetype: modify add: olcAccess olcAccess: to * by self write by * read EOF ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f add_access.ldif


olcAccess: access to dn="ou=group,ou=user,ou=marketer,ou=devops,ou=tester,dc=clemente,dc=com" by anonymous none by self read by dn='ou=serv,dc=clemente,dc=com' read by dn='cn=admins,dc=clemente,dc=com' write 

olcAccess: {0}to dn="ou=group,ou=user,ou=marketer,ou=devops,ou=tester,dc=clemente,dc=com"
by anonymous none
by self read
by dn='ou=serv,dc=clemente,dc=com' read
by dn='cn=admins,dc=clemente,dc=com' write



ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f acl.ldif

ldapsearch -x -H ldap:/// -b 'ou=cs,dc=clemente,dc=com' -D 'cn=asd,dc=clemente,dc=com' -W

ldapsearch -H ldaps:/// -x -W -D 'n=asd,ou=cs,dc=clemente,dc=com' -b 'ou=serv,dc=clemente,dc=com'


ldapsearch -J "1.3.6.1.4.1.42.2.27.9.5.2" -H ldap:/// \
 -D "uid=qwe,ou=user,dc=clemente,dc=com" -W -b "dc=clemente,dc=com" \
 "(objectclass=*)" aclRights


docker run 
--volume /data/my-config.php:/container/service/phpldapadmin/assets/config/config.php 
--detach osixia/phpldapadmin:0.9.0


  PHPLDAPAdmin:
    container_name: ldapadmin
    image: osixia/phpldapadmin:0.9.0
    environment:
        PHPLDAPADMIN_LDAP_HOSTS: ldap
        PHPLDAPADMIN_HTTPS: false
        PHPLDAPADMIN_LDAP_CLIENT_TLS: false
    volumes:
      - /docker/config/config.php:/container/service/phpldapadmin/assets/config/config.php
    ports:
      - 443:443
      - 80:80
```
