<!--
 * @Description:
 * @Author: 焦国峰
 * @Github: https://github.com/clement-jiao
 * @Date: 2019-08-13 23:40:14
 * @LastEditors: clement-jiao
 * @LastEditTime: 2019-08-14 00:12:56
 -->

#CentOS系统初始化的常用命令脚本


```bash

#!/bin/bash

close_selinux(){
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
}

hostname_update(){
    read -p "Please input the new hostname: " SERVER_HOSTNAME
    kernel=`uname -r | awk -F'.' '{print $1}'`
    if [ $kernel == '2' ];then
        sed -i "/HOSTNAME/d" /etc/sysconfig/network
        sed -i "/NETWORKING=yes/a\HOSTNAME=${SERVER_HOSTNAME}" /etc/sysconfig/network
    elif [ $kernel == '3' ];then
        echo "${SERVER_HOSTNAME}" > /etc/hostname
    else
        echo 'The kernel version is not recognized !!!'
        exit 1
    fi
    CURRENT_HOSTNAME=`hostname`
    sed -i "s/${CURRENT_HOSTNAME}/${SERVER_HOSTNAME}/g" /etc/hosts
}

create_user(){
    read -p 'Please input the username: ' username
    read -p 'Please input the password: ' password
    useradd $username
    echo "$username" | passwd --stdin "$password"
    read -p 'Does the user for sodu level?[y/n]' is_sudo
    if [ is_sudo == 'y' -o is_sudo == 'yes' ];then
        root_all=`cat /etc/sudoers | grep 'ALL=(ALL)' | grep root`
        sed -i "/$root_all/a\${user_name}    ALL=(ALL)       ALL" /etc/sudoers
    fi
}

install_tool(){
    yum update -y

    yum install iptables-services vim wget dos2unix git tree lvm2 lsb net-tools openssh-clients vim-enhanced zip unzip telnet lsof ntsysv lrzsz -y

    yum install gcc gcc* gcc-c++ ntp make imake cmake automake autoconf compat* apr* nasm* python-devel bison-devel zlib zlib-devel glibc glibc-devel glib2 libxml glib2-devel libxml2 libxml2-devel bzip2 bzip2-devel libXpm libXpm-devel libidn libidn-devel libtool libtool-ltdl-devel* libmcrypt libmcrypt-devel libevent-devel libmcrypt* libicu-devel libxslt-devel postgresql-devel libaio libaio-devel curl curl-devel perl perl-Net-SSLeay  perl-Time-HiRespcre perl-ExtUtils-MakeMaker perl-DBD-MySQL.* pcre pcre-devel ncurses ncurses-devel openssl openssl-devel openldap openldap-devel openldap-clients openldap-servers krb5 krb5-devel e2fsprogs e2fsprogs-devel libjpeg libpng libjpeg-devel libjpeg-6b libjpeg-devel-6b libpng-devel libtiff-devel freetype freetype-devel fontconfig-devel gd gd-devel expat-devel gettext-devel kernel package screen sysstat flex bison cpio nss_ldap pam-devel compat-libstdc++-33 --skip-broken -y
}

profile_config(){
    echo "" >> /etc/profile
    echo "" >> /etc/rc.local
    sed -i /HISTSIZE/d /etc/profile
    echo 'HISTSIZE=10000' >> /etc/profile
    echo "HISTTIMEFORMAT=\" | `whoami` | %F | %T | \"" >> /etc/profile
    echo "alias ll='ls -l --time-style=\"+%Y-%m-%d %H:%M:%S\"'" >> /etc/profile
    echo "alias date='date \"+%Y-%m-%d %H:%M:%S.%A\"'" >> /etc/profile
    echo "PS1='\[\e[37;40m\][\[\e[33;40m\]\u\[\e[37;40m\]@\[\e[32;40m\]\h \[\e[37;40m\]:\[\e[35;40m\]\w\[\e[37;40m\]]\\$ '" >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'cat /etc/redhat-release' >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'df -Th' >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'date' >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'ulimit -SHn 655350' >> /etc/profile
    echo 'ulimit -SHn 655350' >> /etc/rc.local
    sed -i 's/net.ipv4.tcp_max_syn_backlog = 1024/net.ipv4.tcp_max_syn_backlog = 2048/g' /etc/sysctl.conf
    echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf
    echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
    sysctl -p
}

crontab_config(){
    echo '############################ OM #############################' >> /var/spool/cron/root
    echo '# update the system patch(week7-05:10)' >> /var/spool/cron/root
    echo '10 05 * * 7     yum update -y' >> /var/spool/cron/root
    echo '# release the memory resource(day-05:50)' >> /var/spool/cron/root
    echo '59 06 * * *     echo 1 > /proc/sys/vm/drop_caches' >> /var/spool/cron/root
}

mail_config(){
    echo 'set from=yange@xihua888.com' >> /etc/mail.rc
    echo 'set smtp=smtp.exmail.qq.com' >> /etc/mail.rc
    echo 'set smtp-auth-user=yange@xihua888.com' >> /etc/mail.rc
    echo 'set smtp-auth-password=123456' >> /etc/mail.rc
    echo 'set smtp-auth=login' >> /etc/mail.rc
}

sshport_config(){
    echo 'Port 32822' >> /etc/ssh/sshd_config
    service sshd restart
}

iptables_config(){
    iptables -F -t nat
    iptables -X -t nat
    iptables -Z -t nat
    iptables -X
    iptables -F
    iptables -A INPUT -p tcp -m tcp --dport 32822 -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -p icmp -j ACCEPT
    iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
    iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
    iptables -A INPUT -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j DROP
    iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j DROP
    iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP
    iptables -A INPUT -p tcp -m tcp --tcp-flags PSH,ACK PSH -j DROP
    iptables -A INPUT -p tcp -m tcp --tcp-flags ACK,URG URG -j DROP
    iptables -P INPUT DROP
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD DROP
    service iptables save
    service iptables restart
}

main(){
    close_selinux;
    hostname_update;
    create_user;
    install_tool;
    profile_config;
    crontab_config;
    mail_config;
    sshport_config;
    iptables_config;
    if [ $? -eq 0 ];then
        echo 'server initialization is complate sucessfully'
    fi
}

main
```
