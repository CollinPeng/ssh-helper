#!/bin/bash

read -p "输入脚本安装位置，如果为空则默认安装在当前目录下：" path;

if [ -z "$path" ];then
    # 直接安装在当前目录下
    # 不移动文件，仅仅只是在/usr/local/bin 下创建一个软链接
    path=$(pwd)
    echo $path
else
    if [ ! `echo ${path:0-1}` == "/" ];then
        path=${path}"/"
    fi
    path=${path}"ssh-helper"
    sudo mkdir -p $path

    sudo cp ./ssh-helper.sh $path/
fi


sudo ln -s $path/ssh-helper.sh /usr/local/bin/ssh-helper

cat <<EOF
   _____  __  __ ______ ______ ______ _____ _____
  / ___/ / / / // ____// ____// ____// ___// ___/
  \__ \ / / / // /    / /    / __/   \__ \ \__ \ 
 ___/ // /_/ // /___ / /___ / /___  ___/ /___/ / 
/____/ \____/ \____/ \____//_____/ /____//____/  
                                                 
EOF