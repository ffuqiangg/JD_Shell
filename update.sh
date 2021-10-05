#!/usr/bin/env bash

## 文件路径、脚本网址
dir_shell=$(dirname $(readlink -f "$0"))
url_scripts='https://github.com/shufflewzc/faker2.git'

## 导入配置文件
. $dir_shell/config/config.sh
. $dir_shell/share.sh

## 创建软链接
link_shell
shell_chmod

## npm install
npm_install () {
	local dir_current=$(pwd)
	cd $dir_scripts
	npm install
	cd $dir_current
}

## 克隆脚本，$1：仓库地址，$2：仓库保存路径，$3：分支（可省略）
git_clone_scripts () {
	local url=$1
	local dir=$2
	local branch=$3
	[[ $branch ]] && cmd="-b $branch "
	echo -e "\n===========$(date +%Y-%m-%d-%H-%M)===========\n开始克隆仓库 $url 到 $dir\n"
	git clone $cmd $url $dir
	echo -e "============克隆完毕=============\n"
	npm_install
}

## 更新脚本，$1：仓库地址，$2：仓库保存路径
git_pull_scripts () {
	local url=$1
	local dir_work=$2
	local dir_current=$(pwd)
	[ -f $dir_scripts/package.json ] && scripts_depend_old=$(cat $dir_scripts/package.json)
	cd $dir_work
	echo -e "\n===========$(date +%Y-%m-%d-%H-%M)===========\n开始更新仓库 $url\n"
	git reset --hard && git pull
	echo -e "============更新完毕=============\n"
	cd $dir_current
	[ -f $dir_scripts/package.json ] && scripts_depend_new=$(cat $dir_scripts/package.json)
    [[ "$scripts_depend_old" != "$scripts_depend_new" ]] && npm_install
}

set_config	
if [ -d $dir_scripts/.git ];then
	git_pull_scripts $url_scripts ${dir_scripts}
else
	git_clone_scripts $url_scripts ${dir_scripts}
fi
update_crontab

exit 0
