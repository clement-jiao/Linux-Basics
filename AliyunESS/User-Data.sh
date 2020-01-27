#!/bin/bash
# Qianji-ESS-[001,1]-ECS

JDKVERSION='jdk-8u231.tar.gz'
WORKSPACE_DIR="/workspace"
APPLICATION2_SERVER="172.16.46.169"
ServerList="AppQianjiMemberService AppQianjiDoubangService AppQianjiInfoService AppQianjiMagazineService"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LogPath=/root/slog.log
APPWD='******'  #密码
echo "" > $LogPath

close_selinux(){
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog ------ 1. selinux 已关闭---------" >> $LogPath
    fi
}

install_tool(){
    yum makecache
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog ------ 2. yum 缓存已建立！----------" >> $LogPath
    fi
    yum upgrade -y
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog ------ 3. yum 已更新！----------" >> $LogPath
    fi
    yum install vim wget dos2unix git tree lvm2 lsb net-tools openssh-clients vim-enhanced zip unzip telnet lsof ntsysv lrzsz sshpass nmap bash-completion.noarch screen sysstat htop ansible -y
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog ------ 4. 已安装基础软件！----------" >> $LogPath
    fi
    yum install python-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel libxml2 libxml2-devel bzip2 bzip2-devel libXpm libXpm-devel libidn libidn-devel libtool libtool-ltdl-devel* libmcrypt libmcrypt-devel libevent-devel curl curl-devel openssl openssl-devel libtiff-devel freetype freetype-devel fontconfig-devel flex bison python-jinja2 PyYAML python-paramiko python-babel python-crypto --skip-broken -y
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog ------ 5. 已安装依赖库！----------" >> $LogPath
    fi
    wait
}

envProfile_config(){
    echo "Asia/Shanghai" > /etc/timezone
    echo "" >> /etc/profile
    echo "" >> /etc/rc.local
    # sed -i /HISTSIZE/d /etc/profile
    echo 'HISTSIZE=10000' >> /etc/profile
    echo "HISTTIMEFORMAT=\" | `whoami` | %F | %T | \"" >> /etc/profile
    echo "alias ll='ls -lh --time-style=\"+%Y-%m-%d %H:%M:%S\"'" >> /etc/profile
    echo "alias date='date \"+%Y-%m-%d %H:%M:%S.%A\"'" >> /etc/profile
    # echo "PS1='\[\e[37;40m\][\[\e[33;40m\]\u\[\e[37;40m\]@\[\e[32;40m\]\h \[\e[37;40m\]:\[\e[35;40m\]\w\[\e[37;40m\]]\\$ '" >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'cat /etc/redhat-release' >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'df -Th' >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    echo 'date' >> /etc/profile
    echo "echo '============================================================'" >> /etc/profile
    # echo 'ulimit -SHn 655350' >> /etc/profile
    # echo 'ulimit -SHn 655350' >> /etc/rc.local
    echo 'export JAVA_HOME=/workspace/jdk1.8.0_231' >> /etc/profile
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
    source /etc/profile
    echo "$DATE ----- ScriptLog ------ 6. 环境变量添加完成！----------" >> $LogPath
}

crontab_config(){
    echo '############################ OM #############################' >> /var/spool/cron/root
    echo '# release the memory resource(day-05:50)' >> /var/spool/cron/root
    echo '59 06 * * *     echo 1 > /proc/sys/vm/drop_caches' >> /var/spool/cron/root
    echo "$DATE ----- ScriptLog ------ 7. 定时任务添加完成！----------" >> $LogPath
}

mail_config(){
    echo 'set from=yange@tsinghua.com' >> /etc/mail.rc
    echo 'set smtp=smtp.exmail.tsinghua.com' >> /etc/mail.rc
    echo 'set smtp-auth-user=Clement@tsinghua.com' >> /etc/mail.rc
    echo 'set smtp-auth-password=123456' >> /etc/mail.rc
    echo 'set smtp-auth=login' >> /etc/mail.rc
    echo "$DATE ----- ScriptLog ------ 8. 邮件信息配置完成！----------" >> $LogPath
}

sshport_config(){
    echo 'Port 50622' >> /etc/ssh/sshd_config
    echo 'StrictHostKeyChecking no' >> /etc/ssh/sshd_config
    systemctl restart sshd
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog------ 9. ssh端口修改完成！----------" >> $LogPath
    fi
}

create_user(){
    username='deploy'
    useradd "$username"
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog------ 10. deploy用户添加完成！----------" >> $LogPath
    fi
    echo "$APPWD" | passwd $username --stdin >/dev/null 2>&1
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog------ 11. root密码修改完成！----------" >> $LogPath
    fi
    # echo "$APPWD" | passwd root --stdin >/dev/null 2>&1
    # root_all=`cat /etc/sudoers | grep 'ALL=(ALL)' | grep root`
    # sed -i "/$root_all/a\${user_name}    ALL=(ALL)       ALL" /etc/sudoers
}

check_jdk(){
  mkdir $WORKSPACE_DIR
  # 下载jdk
  sshpass -p $APPWD scp -o StrictHostKeyChecking=no -r deploy@$APPLICATION2_SERVER:/home/deploy/$JDKVERSION $WORKSPACE_DIR >> $LogPath
  if [ $? = 0 ]; then
    echo "$DATE ----- ScriptLog------ 12. jdk下载完成！----------" >> $LogPath
  fi
  wait
  # 解压jdk
  tar zxf $WORKSPACE_DIR/$JDKVERSION -C $WORKSPACE_DIR >> $LogPath
  if [ $? = 0 ]; then
    echo "$DATE ----- ScriptLog------ 13. jdk解压完成！----------" >> $LogPath
  fi
  wait
}

download_ProjectFile(){
  for i in $ServerList;
  do
    # 判断项目文件目录
    APPLICATION_DIR=$WORKSPACE_DIR/$i/latest;    # /workspace/AppQianjiDoubangService
    if [ ! -d $APPLICATION_DIR ]; then
      mkdir -p "$APPLICATION_DIR"                # APPLICATION_DIR: mkdir -p /workspace/AppQianjiDoubangService/latest
      echo "$DATE ----- ScriptLog------ 14. $APPLICATION_DIR 创建完成！----------" >> $LogPath
    fi

    # 下载install和run脚本
    sshpass -p $APPWD scp -o StrictHostKeyChecking=no -r deploy@$APPLICATION2_SERVER:$APPLICATION_DIR/\{$i.jar,run.sh\} $APPLICATION_DIR >> $LogPath
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog------ 15. $i 下载完成！----------" >> $LogPath
    fi
    wait

    # 替换run.sh脚本：APPLICATION_HOME、APPLICATION_JAR，uat需要替换：SPRING_BOOT_OPTS
    sed -i "14c APPLICATION_HOME='$APPLICATION_DIR'" $APPLICATION_DIR/run.sh
    # sed -i "19c SPRING_BOOT_OPTS='--config.profile=uat --eureka.uri=http://172.16.46.168:8301/eureka'" $APPLICATION_DIR/run.sh
    sed -i "22c APPLICATION_JAR='$APPLICATION_DIR/$i.jar'" $APPLICATION_DIR/run.sh
    echo "$DATE ----- ScriptLog------ 16. 运行脚本替换完成！----------" >> $LogPath

    # 初始化权限！
    # chown -R deploy.deploy $WORKSPACE_DIR $JDKFILE

    # 添加执行权限
    chmod +x -R "$APPLICATION_DIR/run.sh"
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog------ 16. $APPLICATION_DIR 已添加执行权限！----------" >> $LogPath
    fi
    cd $APPLICATION_DIR
    /usr/bin/bash $APPLICATION_DIR/run.sh restart >> $LogPath
    if [ $? = 0 ]; then
      echo "$DATE ----- ScriptLog------ 17. $i 启动成功！----------" >> $LogPath
    fi
  done
}

destroy_self(){
  history -c
  echo "" > ~/.bash_history

}

main()
{
  install_tool;
  wait
  check_jdk;
  wait
  close_selinux;
  envProfile_config;
  create_user;
  download_ProjectFile;
}

main
