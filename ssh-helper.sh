#!/bin/bash

# ------------------------------
# Linux 远程服务器管理帮助工具 |
#                              |
# @author Collin               |
# @email  pengcoltom@gmail.com |
# ------------------------------

dbpath='./db'
version="0.0.1";
sedcmd=sed

#------------------ functions start ------------------

# 初始化
# 主要用于检测环境依赖
init() {
  # 如果当前执行的shell是软链接，则找到真正的目录地址 
  if [ -L $0 ];then
    dbpath="$(dirname $(readlink $0))/db"
  fi

  if [ ! -f $dbpath ];then
    touch $dbpath
  fi

  # 如果是mac系统，则判断是否有gsed命令
  if [[ `uname` == 'Darwin' ]];then
    if ! type "gsed" > /dev/null; then
      brew install gnu-sed
    fi
    sedcmd=gsed
  fi
}

# 输出Logo
echoLogo() {
  cat <<EOF
         _           _          _                 
        | |         | |        | |                
 ___ ___| |__ ______| |__   ___| |_ __   ___ _ __ 
/ __/ __| '_ \______| '_ \ / _ \ | '_ \ / _ \ '__|
\__ \__ \ | | |     | | | |  __/ | |_) |  __/ |   
|___/___/_| |_|     |_| |_|\___|_| .__/ \___|_|   
                                 | |              
                                 |_|    
EOF

}
# 检测更新
#
# 使用git来维护版本，在远程服务器上有最新版本编号，
# 当发现有最新版本时，会询问用户是否进行更新
checkUpdate() {
  remote_version="$(curl -s /dev/null http://version.sizeof.io/ssh-helper.html)";
  remote_version=${remote_version//./};
  version=${version//./};
  if [ $remote_version -gt $version ]; then
    read -p "发现新版本，是否需要更新?(输入y/n) " check
    if [ $check == "y" ]; then
      git pull
    fi
  fi
}

# 添加服务器
#
# @param $1 server name(like: collin-tmp)
# @param $2 server address(like: root@127.0.0.1)
# @param $3 auto copy ssh-key(true/false)
addServer() {
  # 如果当前标记已经添加，则提示用户更换标记
  if  [[ `grep ^$1=* $dbpath` ]]; then
    echo -e "\033[31m名称\"$1\"已经使用，请尝试其它名称\033[0m"
    exit 0
  fi

  test -s $dbpath && $sedcmd -i "\$a$1=$2" $dbpath || echo "$1=$2" >> $dbpath

  if [[ $3 == 'y' ]]; then
    ssh-copy-id $2
  fi

  echo -e "\033[32mok\033[0m"
  exit 0
}

# 删除服务器
#
# @param $1 server name 
deleteServer() {
  if [[ ! `grep ^$1=* $dbpath` ]]; then
    echo -e "\033[31m没有找到服务器\"$1\""
    exit 0
  fi

  $sedcmd -i "/$1/d" $dbpath
  echo -e "\033[32m删除\"$1\"成功"
  exit 0
}

# 连接到服务器
#
# @param $1 server name
connectServer() {
  ip=`sed "/^$1/!d;s/.*=//" $dbpath`
  ssh $ip
  exit 0
}


# usage 函数
usage() {
  echoLogo
  echo '

usage: 
  -s server_tag: Connect to the server with the server name
  -h: get help
  -l: get the server list
  -a <server_tag> <server_host[:port]>(localhost root@127.0.0.1)
  -d server_name: delete a server


'
}


getList() {
  printf "%-32s %-10s\n" 地址 名字
  echo -e "--------------------------------------------"
  cat $dbpath | while read line
  do
    name=`echo $line | cut -d \= -f 1`
    host=`echo $line | cut -d \= -f 2`

    printf "%-30s \e[1;31m%-10s\e[0m\n" $host $name 
  done;
}
#------------------ functions end ------------------


# 主流程
init
[ $# == 0 ] && usage

while getopts 's:ad:lh' opt;
do
  case ${opt} in
    a)  # 添加服务器
      if [ $# -eq 3 ]; then
        addServer $2 $3
      elif [ $# -eq 4 ]; then
        addServer $2 $3 $4
      else 
        echo -e "\e[0;32m参数错误\e[0m"
        exit 0
      fi
      ;;
    s)  # 链接服务器
      if [ $# -ne 2 ]; then
        echo "Argument error!!!"
        echo 0
      fi
      
      connectServer $2
      ;;
    d)  # 删除服务器
      if [ $# -ne 2 ]; then
        echo "Argument error!!!"
        exit 0
      fi

      deleteServer $2
      ;;
    l)  # 获取服务器列表
      getList
      ;;
    h)  # 获取帮助
      usage
      ;;
  esac
done
