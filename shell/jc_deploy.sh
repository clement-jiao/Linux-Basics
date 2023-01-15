#!/bin/bash
root_dir="/home/wwwroot"
app_id=jc-magento

server_root_dir=$root_dir/$app_id               # /home/wwwroot/jc-magento
server_pre_link=$root_dir/magento-pre           # /home/wwwroot/magento-pre
server_live_link=$root_dir/magento-live         # /home/wwwroot/magento-live
server_latest_link=$server_root_dir/latest      # /home/wwwroot/jc-magento/latest
server_tar_dir=$server_root_dir/build_package   # /home/wwwroot/jc-magento/build_package
previous_version=$(ls -l $server_latest_link|awk '{ print $NF }')

# env="pro"
env="test"
env_file="jc_${env}_env.php"
index_file="jc_${env}_index.php"
config_file="jc_${env}_config.php"

# git_branch="Production"
git_branch="Test"
git_path="http://git.ibaiqiu.com:9180/magento/Jimmychoo.git"

LOG_LEVEL=2
# 生产环境：magento-live
# 预发布环境：magento-pre
# build: 打包？
# install_live: 切换至生产（同步预发布版本）
# building_pre：不切换预发布环境，预发布始终保持最新版本（前端包始终从生产目录复制出来）


function log_info () {
    content="[INFO] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 2  ] && echo -e "\033[32m"  ${content} "\033[0m"
}

function log_warn () {
    content="[WARN] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 3  ] && echo -e "\033[33m" ${content} "\033[0m"
}

function log_err () {
    content="[ERROR] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 4  ] && echo -e "\033[31m" ${content} "\033[0m"
}

build_magento () {

    if [ ! -d $server_root_dir ]; then
        log_err "not exist $server_root_dir!"
        return 1
    fi

    DATE=$(date +%Y%m%d%H%M%S)
    current_version_dir=$server_root_dir/magento-${DATE}
    server_config_dir=$current_version_dir/config

    log_info "start to install $app_id to $current_version_dir\n"

    mkdir -pv $current_version_dir && cd $current_version_dir
    git clone -b $git_branch $git_path $current_version_dir
    if [ $? != 0 ]; then
        log_err "git clone error!"
        return 1
    fi

    if [ -f $current_version_dir/app/etc/env.php ];then
        log_info "env.php exist, delete env file."
        rm -rf $current_version_dir/app/etc/env.php
    fi
    log_info "cp: /config/$env_file to /app/etc/env.php"
    cp -rf $server_config_dir/$env_file $current_version_dir/app/etc/env.php

    log_info "change env file id_prefix"
    sed -i 's/3ac_/pre_/g' $current_version_dir/app/etc/env.php

    log_info "cp: /config/$config_file to /app/etc/config.php"
    cp -rf $server_config_dir/$config_file $current_version_dir/app/etc/config.php

    log_info "cp: /config/jimmychoo.sh to $current_version_dir"
    cp -rf $server_config_dir/jimmychoo.sh $current_version_dir

    log_info "tar: decompress vendor.tar.xz to $current_version_dir/vendor"
    /usr/bin/tar Jxf $server_config_dir/vendor.tar.xz -C $current_version_dir/vendor

    front_dir=$(find $server_pre_link/pub/media/pwa -maxdepth 1 -type d -name "20*"| sort -nr | head -n +3)
    log_info "find front dir: $front_dir"

    mkdir -pv $current_version_dir/pub/media/pwa
    mkdir -pv $current_version_dir/pub/media/upload/default
    pay_cert_dir=$server_live_link/pub/media/upload/default

    if [ -n "$front_dir" ]; then
        rm -rf $current_version_dir/pub/index.php
        rm -rf $current_version_dir/pub/media/pwa_file

        log_info "cp: $front_dir \n to $current_version_dir/pub/media/pwa/"
        # ssl cert
        if [ -n $pay_cert_dir ]; then
            log_info "cp: live pay cert to $current_version_dir"
            cp -rf $pay_cert_dir/*  $current_version_dir/pub/media/upload/default/
        else
            log_warn "cert dir is empty!"
        fi
        # front html
        cp -rf $front_dir $current_version_dir/pub/media/pwa/
        cp -rf $server_live_link/pub/media/pwa_file $current_version_dir/pub/media/

        log_info "cp: /config/$index_file to $current_version_dir/pub/index.php"
        cp -rf $server_config_dir/$index_file $current_version_dir/pub/index.php
    else
        log_err "previous version front file : $front_dir not exist!"
        return 1
    fi
    # cp -rf $server_pre_link/* $current_version_dir/
    # sshpass -p  scp -r :$JAR_DIR/* $current_version_dir/
    
    if [ -f jimmychoo.sh ]; then
        chown -R www:www $current_version_dir
        chown www:www $server_latest_link
        chown www:www $server_pre_link
        chmod +x jimmychoo.sh
        /bin/sh  jimmychoo.sh
        if [ $? != 0 ]; then
          log_err "build script exec faild"
        return 1
    fi
    else
        log_err "build script not exist"
        return 1
    fi
}
checkfile (){
    for i in {2..5}; do
        file_nu=$(/usr/bin/sshpass ssh root@10.0.0.${i} find ${previous_version} -type f | wc -l)
        file_size=$(/usr/bin/sshpass ssh root@10.0.0.${i} du -sh ${previous_version} | awk '{ print $1 }')
        echo -e "10.0.0.${i}\tfile num: ${file_nu}\tfile size: ${file_size}"
    done
    
}
syncfile (){
    # systemctl stop lsyncd.service

    tar_name=$(echo ${previous_version} | awk -F '/' '{ print $NF }')
    mkdir -pv $server_tar_dir
    tar zcf $server_tar_dir/ $previous_version
    sshpass ssh root@
}
rollback (){
    echo "1"
}
install_pre () {
    if [ -L $server_latest_link ] && [ -L $server_pre_link ]; then
        log_info "unlink: $server_latest_link"
        unlink $server_latest_link
        
        log_info "unlink: $server_pre_link"
        unlink $server_pre_link
    else
        log_warn "project link not exist!"
    fi

    if  [ -d $server_latest_link ]  || [ -f $server_latest_link ]; then
        log_info "link name is exist, delete it: $server_latest_link"
        rm -rf $server_latest_link
    fi

    ln -sv $current_version_dir $server_latest_link
    ln -sv $current_version_dir $server_pre_link
    cd $current_version_dir
    chmod -R 777 generated/ pub/ var/
    log_info "finished to install! $app_id to $current_version_dir"
}

install_live () {
    # live 软链接必须存在
    # 获取live版本根目录
    # 清空 latest 版本 cert 证书
    # 拷贝 live 版cert证书，至 latest 版
    # 更换软链接

    if [ -L $server_latest_link ] && [ -L $server_pre_link ] && [ -L $server_live_link ]; then
        # 拷贝银联支付证书，live_link 必须正确存在
        pre_vers_dir=$(ls -l $server_pre_link | awk '{ print $NF }')
        pre_pay_cert_dir=$pre_vers_dir/pub/media/upload/default
        live_vers_dir=$(ls -l $server_live_link | awk '{ print $NF }')
        live_pay_cert_dir=$live_vers_dir/pub/media/upload/default
    
        if [ ! -d $pre_pay_cert_dir ]; then
            log_warn "pre pay cert dir not exist!"
            mkdir -pv $pre_pay_cert_dir
        fi

        # live_ssl_cert
        if [[ $live_pay_cert_dir =~ "jc-magento" ]]; then
            # 清空 pre cert 目录文件，拷贝文件
            find $pre_pay_cert_dir -type f | xargs -I {} rm -f {}
            find $live_pay_cert_dir -type f | xargs -I {} cp {} -rf $pre_pay_cert_dir
        else
            log_err "live pay cert dir is incorrect"
            return 1
        fi

        if [ -f $server_pre_link/app/etc/env.php ];then
            log_info "change env file id_prefix to live_"
            sed -i 's/pre_/live_/g' $server_pre_link/app/etc/env.php
        else
            log_err "env file not exist!"
            return 1
        fi
        log_info "unlink: $server_live_link"
        unlink $server_live_link
        
        log_info "change live version to ${pre_vers_dir}"
        ln -sv $pre_vers_dir $server_live_link

        log_info "clean magento index and cache"
        /usr/local/php/bin/php $server_live_link/bin/magento indexer:reindex
        /usr/local/php/bin/php $server_live_link/bin/magento c:f

        log_info "restart crond service"
        systemctl restart crond.service

        log_info "change ${server_live_link} previleges"
        chown www:www -R $server_live_link/*
        chmod -R 777 generated/ pub/ var/
        
        log_info "finished to install! magento live server to $pre_vers_dir"
    else
        log_err "magento latest link or magento-pre link not exist!"
        return 1
    fi
}

case "$1" in
    build)
        log_info "start building magento server"
        build_magento
        if [ "$?" != 0 ] ; then
            log_err "magento server build failed"
            exit 1
        fi
    ;;
    install_pre)
        log_info "start building magento pre server"
        build_magento
        if [ "$?" != 0 ] ; then
            log_err "magento pre server build failed"
            exit 1
        fi
        install_pre
    ;;
    install_live)
        log_info "start install magento live server\n"
        install_live
        if [ "$?" != 0 ] ; then
            log_err "magento server install failed"
            exit 1
        fi
    ;;
    rollback)
        log_info "rollback magento server to $2"
        rollback
        if [ "$?" != 0 ] ; then
                log_err " failed"
                exit 1
        fi
    ;;
    checkfile)
        log_info "check web file num"
        checkfile
        if [ "$?" != 0 ] ; then
                log_err " check failed"
                exit 1
        fi
    ;;
    *)
        log_err "Please usage: { install_pre | install_live | checkfile}"
        exit 1
    ;;
esac