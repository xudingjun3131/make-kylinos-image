#!/bin/bash


#VERSION=$(uname -m)-$(nkvers | sed -n '10p' | awk -F "/" '{print $1 $3}' | awk '{print $2 $3 $4}' | tr '(|)' -)
VERSION=$(uname -m)-$(cat /etc/issue.net |sed  's/ /_/g'|sed 's/_$//g')
RELEASEVER=$(rpm -qi UnionTech-release |grep Release |awk '{print $NF}' |awk -F '.' '{print $1}' |cut -c 1-4)
clear

# ${FUNCNAME[1]} 表示调用该函数的函数
# $LINENO 表示当前代码行号
Log(){
        local log_level=$1
        local log_info=$2
        local line=$3
        local script_name=$(basename $0)

        case ${log_level} in
"INFO")
echo -e "\033[32m$(date "+%Y-%m-%d %T.%N") [INFO]: ${log_info}\033[0m";;
"WARN")
echo -e "\033[33m$(date "+%Y+%m+%d %T.%N") [WARN]: ${log_info}\033[0m";;
"ERROR")
echo -e "\033[31m$(date "+%Y-%m-%d %T.%N") [ERROR ${script_name} ${FUNCNAME[1]}:$line]: ${log_info}\033[0m";;

        *)
echo -e "${@}"
        ;;
esac
}

function base_image {
        # 部署 yum 源 for ISO
        # [ ! -d /etc/yum.repos.d/bak ] && mkdir /etc/yum.repos.d/bak
        # mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
        # mount /dev/sr0 /mnt/ 1>/dev/null 2>&1
        # yum-config-manager --add-repo=file:///mnt 1>/dev/null 2>&1 && echo "gpgcheck=0" >>/etc/yum.repos.d/mnt.repo

        # 拷贝环境变量，安装基础包
        [ ! -d /uos-$VERSION ] && mkdir /uos-$VERSION
        Log INFO "系统正在为 docker image 安装基础包，请等待......"
        yum -y --installroot=/uos-$VERSION install yum net-tools vim iproute iputils procps-ng  --releasever=${RELEASEVER}
        cp /etc/skel/.bash* /uos-$VERSION/root && echo > /uos-$VERSION/root/.bash_history
        cp /etc/dnf/vars/* /uos-$VERSION/etc/dnf/vars
        if [[ "$RELEASEVER" == "1050" ]];then
                cp /etc/yum.repos.d/UnionTechOS-ufu.repo /uos-$VERSION/etc/yum.repos.d/UniontechOS.repo
        fi

        Log INFO "安装完毕，正在进行打包镜像......"
        cd /uos-$VERSION && tar -zcvpf /root/uos-$VERSION.tar --exclude=proc --exclude=sys --exclude=run --exclude=boot . 1>/dev/null 2>&1

        Log INFO "镜像制作完毕，存取路径是 /root/uos-$VERSION.tar"
}

base_image
