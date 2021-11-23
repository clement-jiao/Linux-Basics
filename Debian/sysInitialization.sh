#!/bin/bash
# chmod +x i.sh && bash i.sh

hostname_update(){
    read -p "Please input the new hostname: " SERVER_HOSTNAME
    /usr/bin/hostnamectl set-hostname $SERVER_HOSTNAME
}

create_user(){
    read -p 'Whether to create a user: [y/n]' is_createUser

    if [ $is_createUser == 'y' -o $is_createUser == 'yes' ];then
        read -p 'Please input the username: ' username
        read -p 'Please input the password: ' password
        useradd $username
        echo "$username" | passwd --stdin "$password"
        # read -p 'Does the user for sodu level?[y/n]' is_sudo
        # if [ is_sudo == 'y' -o is_sudo == 'yes' ];then
        #     root_all=`cat /etc/sudoers | grep 'ALL=(ALL)' | grep root`
        #     sed -i "/$root_all/a\${user_name}    ALL=(ALL)       ALL" /etc/sudoers
        # fi
    fi
}

install_tool(){
    # sed -e 's/mirrorlist/#mirrorlist/g' -e 's|#baseurl=http://mirror.centos.org/|baseurl=http://mirror.sjtu.edu.cn/|g' -i.bak /etc/apt-get.repos.d/CentOS-Base.repo
    # 查询  backports 软件包 : dpkg-query -W | grep ~bpo
    echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" | tee -a /etc/apt/sources.list.d/backports.list
    apt-get purge debian-backports-keyringw
    apt-get update
    apt-get install -y  vim wget git tree net-tools vim bzip2 zip unzip telnet lsof wget curl ncdu htop nethogs
    read -p 'install a docker: [y/n]' install_docker
    echo $install_docker
    if [ $install_docker == 'y' -o $install_docker == 'yes' ];then
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
    fi
}

profile_config(){
    echo "" >> /etc/profile
    echo "" >> /etc/rc.local
    sed -i /HISTSIZE/d /etc/profile
    echo 'HISTSIZE=10000' >> /etc/profile
    echo "HISTTIMEFORMAT=\" | `whoami` | %F | %T | \"" >> /etc/profile
    # echo "alias ll='ls -l --time-style=\"+%Y-%m-%d %H:%M:%S\"'" >> /etc/profile
    # echo "alias date='date \"+%Y-%m-%d\ %H:%M:%S.%A\"'" >> /etc/profile
    # echo "PS1='\[\e[37;40m\][\[\e[33;40m\]\u\[\e[37;40m\]@\[\e[32;40m\]\h \[\e[37;40m\]:\[\e[35;40m\]\w\[\e[37;40m\]]\\$ '" >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo "lsb_release -a|grep Description" >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo "df -Th" >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'date "+%Y-%m-%d %H:%M:%S.%A"' >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'ulimit -SHn 655350' >> /etc/profile
    echo 'ulimit -SHn 655350' >> /etc/rc.local
    echo 'syntax on'    >> ~/.vimrc
    echo 'set mouse=""' >> ~/.vimrc
    echo 'set autoindent'  >> ~/.vimrc    # 自动对齐
    echo 'set smartindent' >> ~/.vimrc   # 智能对齐
    echo 'set showmatch'   >> ~/.vimrc     # 括号匹配模式
    echo 'set ruler'  >> ~/.vimrc         # 显示状态行
    echo 'set incsearch'  >> ~/.vimrc
    echo 'set tabstop=4'  >> ~/.vimrc     # tab键为4个空格
    echo 'set shiftwidth=4'   >> ~/.vimrc
    echo 'set softtabstop=4'  >> ~/.vimrc
    echo 'set clipboard+=unnamed'  >> ~/.vimrc # 与windows共享剪贴板
    echo 'set fileencodings=utf-8,gb2312,gbk,gb18030'  >> ~/.vimrc
    echo 'set termencoding=utf-8'  >> ~/.vimrc
    echo 'set encoding=prc'  >> ~/.vimrc
    # sed -i 's/net.ipv4.tcp_max_syn_backlog = 1024/net.ipv4.tcp_max_syn_backlog = 2048/g' /etc/sysctl.conf
    # echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf
    # echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
    # sysctl -p
}

crontab_config(){
    echo '############################ OM #############################' >> /var/spool/cron/root
    echo '# update the system patch(week7-05:10)' >> /var/spool/cron/root
    echo '10 05 * * 7     apt-get update -y' >> /var/spool/cron/root
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
    # create_user;
    # hostname_update;
    install_tool;
    # profile_config;
    # close_selinux;
    # crontab_config;
    # mail_config;
    # sshport_config;
    # iptables_config;
    if [ $? -eq 0 ];then
        echo 'server initialization is complate sucessfully'
        # rm -rf $0
    fi
}

main
