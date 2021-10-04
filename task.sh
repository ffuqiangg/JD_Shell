#!/bin/bash

## 路径
dir_shell=$(dirname $(readlink -f "$0"))

## 导入配置文件，通用函数变量
. $dir_shell/config.sh
. $dir_shell/share.sh

## $1：文件名不带后缀 $2：=now取消随机延迟 
if [[ $2 = now ]];then
	sleep_num=0
else
	sleep_num=$((RANDOM%300+1))
fi

make_dir $dir_log/$1 && sleep $sleep_num; node $dir_scripts/$1.js 2>&1 | tee $dir_log/$1/$(date +%Y-%m-%d-%H-%M-%S).log

exit 0