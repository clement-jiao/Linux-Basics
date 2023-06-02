#!/bin/bash
root_dir="/home/wwwroot"
app_id=jc-magento

server_root_dir=$root_dir/$app_id               # /home/wwwroot/jc-magento
server_pre_link=$root_dir/magento-pre           # /home/wwwroot/magento-pre
server_live_link=$root_dir/magento-live         # /home/wwwroot/magento-live
server_latest_link=$server_root_dir/latest      # /home/wwwroot/jc-magento/latest
server_build_dir=$server_root_dir/build_package   # /home/wwwroot/jc-magento/build_package
previous_version=$(ls -l $server_latest_link|awk '{ print $NF }')

#########################
local_ip=$(/usr/sbin/ip address show ens192|grep 'inet '|awk '{ print $2 }')
if [ $local_ip == "10.0.0.2/24" ]; then
    file_env="pro"
    git_branch="Production"
elif [ $local_ip == "10.0.0.18/24" ]; then
    file_env="test"
    git_branch="Test"
else
    echo 'server ip err'
    exit 1
fi
echo "current system env: ${file_env}, git branch: ${git_branch}"
#########################

env_file="jc_${file_env}_env.php"
index_file="jc_${file_env}_index.php"
config_file="jc_${file_env}_config.php"

git_path="http://git.ibaiqiu.com:9180/magento/Jimmychoo.git"

LOG_LEVEL=2
# 生产环境：magento-live
# 预发布环境：magento-pre
# build: 打包？
# install_live: 切换至生产（同步预发布版本）
# building_pre：不切换预发布环境，预发布始终保持最新版本（前端包始终从生产目录复制出来）


function log_info(){
    content="[INFO] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 2  ] && echo -e "\033[32m"  ${content} "\033[0m"
}

function log_warn(){
    content="[WARN] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 3  ] && echo -e "\033[33m" ${content} "\033[0m"
}

function log_err(){
    content="[ERROR] [$(date '+%Y-%m-%d %H:%M:%S')] $@"
    [ $LOG_LEVEL -le 4  ] && echo -e "\033[31m" ${content} "\033[0m"
}

function build_magento(){
    if [ ! -d $server_root_dir ]; then
        log_err "not exist $server_root_dir!"
        return 1
    fi

    DATE=$(date +%Y%m%d%H%M%S)
    relative_path=magento-${DATE}
    current_version_dir=$server_root_dir/${relative_path}
    server_config_dir=$current_version_dir/config

    log_info "start to install $app_id to $current_version_dir\n"

    mkdir -pv $current_version_dir && cd $current_version_dir
    git clone -b $git_branch $git_path $current_version_dir
    if [ $? != 0 ]; then
        log_err "git clone error!"
        return 1
    fi

    if [ -f $current_version_dir/app/etc/env.php ];then
        log_warn "env.php exist, delete env file."
        rm -f --verbose $current_version_dir/app/etc/env.php
    fi
    log_info "cp: /config/$env_file to /app/etc/env.php"
    cp -rfv $server_config_dir/$env_file $current_version_dir/app/etc/env.php

    log_info "change env file id_prefix"
    sed -i 's/3ac_/pre_/g' $current_version_dir/app/etc/env.php

    log_info "cp: /config/$config_file to /app/etc/config.php"
    cp -rfv $server_config_dir/$config_file $current_version_dir/app/etc/config.php

    log_info "cp: /config/jimmychoo.sh to $current_version_dir"
    cp -rfv $server_config_dir/jimmychoo.sh $current_version_dir

    log_info "tar: decompress vendor.tar.xz to $current_version_dir/vendor"
    /usr/bin/tar Jxf $server_config_dir/vendor.tar.xz -C $current_version_dir/vendor

    # front_dir=$(find $server_live_link/pub/media/pwa -maxdepth 1 -type d -name "20*"| sort -nr | head -n +3)
    front_dir=$(find $server_live_link/pub/media/pwa -maxdepth 1 -type d -name "20*")
    log_info "find front dir: $front_dir"

    mkdir -pv $current_version_dir/pub/media/pwa
    mkdir -pv $current_version_dir/pub/media/upload/default
    pay_cert_dir=$server_live_link/pub/media/upload/default
    sitemap_xml=$server_live_link/pub/sitemap.xml

    if [ -n "$front_dir" ]; then
        rm -f --verbose $current_version_dir/pub/index.php
        rm -f --verbose $current_version_dir/pub/media/pwa_file

        log_info "cp: $front_dir \n to $current_version_dir/pub/media/pwa/"
        # ssl cert
        if [ -n $pay_cert_dir ]; then
            log_info "cp: live pay cert to $current_version_dir"
            cp -rfv $pay_cert_dir/*  $current_version_dir/pub/media/upload/default/
        else
            log_warn "cert dir is empty!"
        fi
        # front html
        cp -rf  $front_dir $current_version_dir/pub/media/pwa/
        cp -rfv $server_live_link/pub/media/pwa_file $current_version_dir/pub/media/

        log_info "cp: /config/$index_file to $current_version_dir/pub/index.php"
        cp -rfv $server_config_dir/$index_file $current_version_dir/pub/index.php

        # sitemap xml
        log_info "cp: $sitemap_xml to $current_version_dir/pub/"
        cp -rfv $sitemap_xml $current_version_dir/pub/
    else
        log_err "previous version front file : $front_dir not exist!"
        return 1
    fi
    # cp -rfv $server_pre_link/* $current_version_dir/
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

    local_ip=$(/usr/sbin/ip address show ens192|grep 'inet '|awk '{ print $2 }')
    if [ "${file_env}" == "pro" ] && [ "${git_branch}" == "Production" ] && [ "${local_ip}" == "10.0.0.2/24" ]; then
        # 压缩生产项目目录
        # package_name = magento-20221215000606.tar.gz
        # relative_path = 'magento-20221215000606'
        # server_build_dir = /home/wwwroot/jc-magento/build_package/magento-20221215000606.tar.gz

        mkdir -pv $server_build_dir
        cd /home/wwwroot/jc-magento
        package_name=${relative_path}.tar.gz

        log_info "start compressing ${relative_path} dir"
        tar zcf ${server_build_dir}/${package_name} ${relative_path}
        if [ "$?" == 0 ] ; then
            log_info "compress ${relative_path} dir success!"
        else
            log_err "compress dir err: ${relative_path}"
            return 1
        fi
    fi
}
function checkfile(){
    check_addr_list=("10.0.0.2" "10.0.0.3" "10.0.0.4" "10.0.0.5")
    for i in ${check_addr_list[@]}; do
        ip_addr="${i}"
        file_nu=$(/usr/bin/sshpass ssh root@${ip_addr} find ${previous_version} -type f | wc -l)
        file_size=$(/usr/bin/sshpass ssh root@${ip_addr} du -sh ${previous_version} | awk '{ print $1 }')
        echo -e "${ip_addr}\tfile num: ${file_nu}\tfile size: ${file_size}"
    done
}
function clean_magento_cache(){
    clean_addr_list=("10.0.0.2" "10.0.0.3" "10.0.0.4" "10.0.0.5")
    for i in ${clean_addr_list[@]}; do
        ip_addr="${i}"
        log_info "clean magento cache and restart php-fpm: ${ip_addr}"
        # /usr/local/php/bin/php ${server_live_link}/bin/magento indexer:reindex
        sshpass ssh root@${ip_addr} """
        service php-fpm restart
        /usr/local/php/bin/php ${server_live_link}/bin/magento c:f
        service php-fpm restart
        """
    done
}
function syncfile(){
    # systemctl stop lsyncd.service

    # package_name=$(echo ${previous_version} | awk -F '/' '{ print $NF }')
    # mkdir -pv $server_build_dir
    # tar zcf ${package_name}.tar.gz $previous_version
    sync_addr_list=("10.0.0.3" "10.0.0.4" "10.0.0.5")
    for i in ${sync_addr_list[@]}; do
        ip_addr="${i}"

        log_info "${ip_addr}: sync project file"
        sshpass ssh root@${ip_addr} mkdir -pv ${server_build_dir}
        scp ${server_build_dir}/${package_name} root@${ip_addr}:${server_build_dir}

        log_info "${ip_addr}: decompression project file"
        sshpass ssh root@${ip_addr} "tar zxf ${server_build_dir}/${package_name} -C ${server_root_dir}"

        log_info "${ip_addr}: create latest and magento-pre link"
        sshpass ssh root@${ip_addr} """ln -svnf ${current_version_dir} ${server_latest_link}
        ln -svnf ${current_version_dir} ${server_pre_link}"""
    done
}
function test_clean_magento_cache(){
    ip_addr="10.0.0.18"
    log_info "test_clean_magento_cache"
    log_info "clean magento cache and restart php-fpm: ${ip_addr}"
    sshpass ssh root@${ip_addr} """
    service php-fpm restart
    /usr/local/php/bin/php $server_pre_link/bin/magento indexer:reindex
    /usr/local/php/bin/php $server_pre_link/bin/magento c:f
    service php-fpm restart"""
}
function test_syncfile(){
    ip_addr="10.0.0.18"
    log_info "test_syncfile"
    sshpass ssh root@${ip_addr} mkdir -pv $server_build_dir
    scp $server_build_dir/$package_name root@${ip_addr}:$server_build_dir

    log_info "decompression project file"
    sshpass ssh root@${ip_addr} "tar zxf $server_build_dir/$package_name -C $server_root_dir"

    log_info "create latest and magento-pre link"
    ln -svnf ${current_version_dir} ${server_root_dir}/latest
    sshpass ssh root@${ip_addr} """ln -svnf $current_version_dir $server_root_dir/latest
    ln -svnf $current_version_dir $server_pre_link"""
}
function rollback(){
    echo "1"
}
function install_pre(){
    # 预发版环境

    if [ -L $server_latest_link ] && [ -L $server_pre_link ]; then
        log_info "unlink: $server_latest_link"
        unlink $server_latest_link

        log_info "unlink: $server_pre_link"
        unlink $server_pre_link
    else
        log_warn "project link not exist!"
    fi

    if  [ -d $server_latest_link ] || [ -f $server_latest_link ]; then
        log_warn "link name is exist, delete it: $server_latest_link"
        rm -rf --verbose $server_latest_link
    fi

    ln -svnf ${current_version_dir} ${server_latest_link}
    ln -svnf ${current_version_dir} ${server_pre_link}
    cd ${current_version_dir}
    chmod -R 777 generated/ pub/ var/

    local_ip=$(/usr/sbin/ip address show ens192|grep 'inet '|awk '{ print $2 }')
    if [ "${file_env}" == "pro" ] && [ "${git_branch}" == "Production" ] && [ "${local_ip}" == "10.0.0.2/24" ]; then
        log_info "starting sync code"
        if [ -f $server_build_dir/$package_name ];then
            # clean 是否要放到 syncfile 中?
            syncfile
            clean_magento_cache
        fi
    else
        log_info "starting sync code"

        log_info "${ip_addr}: create latest and magento-pre link"
        ln -svnf ${current_version_dir} ${server_latest_link}
        ln -svnf ${current_version_dir} ${server_pre_link}

        # log_info "clean magento cache and restart php-fpm: ${ip_addr}"
        # /usr/local/php/bin/php $server_pre_link/bin/magento indexer:reindex
        # /usr/local/php/bin/php $server_pre_link/bin/magento c:f
        # service php-fpm restart
    fi
    log_info "current system env: ${file_env}, git branch: ${git_branch}"
    log_info "finished to install! magento pre server $app_id to $current_version_dir"
}

function install_live(){
    # 生产环境
    # live 软链接必须存在
    # 获取 live 版本根目录
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

        if [ ! -d $pre_pay_cert_dir ]; then
            echo "pre_pay_cert_dir err"
            # live_ssl_cert old
            # if [[ $live_pay_cert_dir =~ "jc-magento" ]]; then
            #     # 清空 pre cert 目录文件，拷贝文件
            #     find $pre_pay_cert_dir -type f | xargs -I {} rm -f {}
            #     find $live_pay_cert_dir -type f | xargs -I {} cp {} -rf $pre_pay_cert_dir
            # else
            #     log_err "live pay cert dir is incorrect"
            #     return 1
            # fi

            # if [ -f $server_pre_link/app/etc/env.php ];then
            #     # 此处判断可以不需要，env 文件必须存在 git 中
            #     log_info "change env file id_prefix to live_"
            #     sed -i 's/pre_/live_/g' $server_pre_link/app/etc/env.php
            # else
            #     log_err "env file not exist!"
            #     return 1
            # fi

            # log_info "unlink: $server_live_link"
            # unlink $server_live_link

            # log_info "change live version to ${pre_vers_dir}"
            # ln -sv ${pre_vers_dir} ${server_live_link}

            # log_info "clean magento index and cache"
            # /usr/local/php/bin/php $server_live_link/bin/magento indexer:reindex
            # /usr/local/php/bin/php $server_live_link/bin/magento c:f

            # log_info "restart crond service"
            # systemctl restart crond.service

            # log_info "change ${server_live_link} previleges"
            # chown www:www -R $server_live_link/
            # chmod -R 777 $live_pay_cert_dir
        fi

        # --- new
        # live_ssl_cert new ( 是否开始加入循环？ 是，可以从0.2开始 拷贝文件从 magento-live 处进行复制)

        live_addr_list=("10.0.0.18")
        local_ip=$(/usr/sbin/ip address show ens192|grep 'inet '|awk '{ print $2 }')
        if [ "${file_env}" == "pro" ] && [ "${git_branch}" == "Production" ] && [ "${local_ip}" == "10.0.0.2/24" ]; then
            live_addr_list=("10.0.0.2" "10.0.0.3" "10.0.0.4" "10.0.0.5")
        fi

        for i in ${live_addr_list[@]};do
            ip_addr="${i}"
            if [[ $live_pay_cert_dir =~ "jc-magento" ]]; then
                # 清空 pre cert 目录文件，拷贝文件
                log_info "${ip_addr}: clean pre pay cert dir"
                sshpass ssh root@${ip_addr} "find ${pre_pay_cert_dir} -type f | xargs -I {} rm -f --verbose {}"

                log_info "${ip_addr}: scp pay cert"
                find $live_pay_cert_dir -type f | xargs -I {} scp -r {} root@${ip_addr}:$pre_pay_cert_dir

                log_info "${ip_addr}: change env file id_prefix to live_"
                sshpass ssh root@${ip_addr} "sed -i 's/pre_/live_/g' ${server_pre_link}/app/etc/env.php"
            else
                log_err "live pay cert dir is incorrect"
                return 1
            fi

            log_info "${ip_addr}: unlink ${server_live_link}"
            sshpass ssh root@${ip_addr} "unlink ${server_live_link}"

            log_info "${ip_addr}: change live version to ${pre_vers_dir}"
            sshpass ssh root@${ip_addr} "ln -svnf ${pre_vers_dir} ${server_live_link}"

            log_info "clean magento index and cache"
            sshpass ssh root@${ip_addr} "/usr/local/php/bin/php ${server_live_link}/bin/magento indexer:reindex"
            sshpass ssh root@${ip_addr} "/usr/local/php/bin/php ${server_live_link}/bin/magento c:f"

            log_info "change ${server_live_link} privileges"
            sshpass ssh root@${ip_addr} "chown www:www -R ${server_live_link}/"
            sshpass ssh root@${ip_addr} "chmod -R 777 ${live_pay_cert_dir}"

            log_info "${ip_addr}: restart php-fpm"
            sshpass ssh root@${ip_addr} "service php-fpm restart"
        done

        if [ "${file_env}" == "test" ] && [ "${git_branch}" == "Test" ]; then
            log_info "restart crond service"
            systemctl restart crond.service
        fi

        log_info "current system env: ${file_env}, git branch: ${git_branch}"
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

        # stop sync file
        log_info "stopped lsyncd service"
        systemctl stop lsyncd.service

        # build package
        build_magento
        if [ "$?" != 0 ] ; then
            log_err "magento pre server build failed"
            log_info "lsyncd service start"
            systemctl start lsyncd.service
            exit 1
        fi
        install_pre
        log_info "lsyncd service start"
        systemctl start lsyncd.service
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
