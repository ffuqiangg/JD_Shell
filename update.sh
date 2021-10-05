#!/usr/bin/env bash

## 文件路径、脚本网址
dir_shell=$(dirname $(readlink -f "$0"))
url_scripts='https://github.com/shufflewzc/faker2.git'

## 导入配置文件
. $dir_shell/config/config.sh
. $dir_shell/share.sh

## 用于复制宠汪汪兑换脚本的变量
filepath1=$dir_scripts/jd_joy_reward.js
filepath2=$dir_scripts/jd_joy_reward2.js

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

## 更新 shell 
update_shell () {
	local dir_current=$(pwd)
	cd $dir_shell
	git reset --hard && git pull
	cd $dir_current
}

## 复制宠汪汪积分兑换脚本，修改脚本变量名
cp_joyreward_scripts () {
	cp $filepath1 $filepath2 && sed -i 's/JD_JOY_REWARD_NAME/JD_JOY_REWARD_NAME2/g' $file2
}

## 更新 own 所有 raw 文件
update_own_raw () {
	local rm_mark
	[[ ${#OwnRawFile[*]} -gt 0 ]] && echo -e "---------------------------------\n"
	for ((i=0; i<${#OwnRawFile[*]}; i++)); do
		raw_file_name[$i]=$(echo ${OwnRawFile[i]} | awk -F "/" '{print $NF}')
		echo -e "开始下载：${OwnRawFile[i]} \n\n保存路径：$dir_raw/${raw_file_name[$i]}\n"
		make_dir $dir_raw
		wget -q --no-check-certificate -O "$dir_raw/${raw_file_name[$i]}.new" ${OwnRawFile[i]}
        if [[ $? -eq 0 ]]; then
            mv "$dir_raw/${raw_file_name[$i]}.new" "$dir_raw/${raw_file_name[$i]}"
            echo -e "下载 ${raw_file_name[$i]} 成功...\n"
        else
            echo -e "下载 ${raw_file_name[$i]} 失败，保留之前正常下载的版本...\n"
            [ -f "$dir_raw/${raw_file_name[$i]}.new" ] && rm -f "$dir_raw/${raw_file_name[$i]}.new"
        fi
        if [[ ! -f $dir_scripts/raw_${raw_file_name[$i]} || $dir_raw/${raw_file_name[$i]} -nt $dir_scripts/raw_${raw_file_name[$i]} ]]; then
        	cp "$dir_raw/${raw_file_name[$i]}" "$dir_scripts/raw_${raw_file_name[$i]}"
        fi
	done

	for file in $(ls $dir_raw); do
        rm_mark="yes"
        for ((i=0; i<${#raw_file_name[*]}; i++)); do
            if [[ $file == ${raw_file_name[$i]} ]]; then
                rm_mark="no"
                break
            fi
        done
        [[ $rm_mark == yes ]] && rm -f $dir_raw/$file 2>/dev/null
    done
}

## 创建脚本清单
create_scripts_list () {
	ls $dir_shell/scripts/*.js > $dir_shell/scripts.list.new
	scripts_list_new=$dir_shell/scripts.list.new
}

## 更新脚本清单
update_scripts_list () {
	mv $dir_shell/scripts.list.new $file_scripts_list
}

## 发送定时任务增减通知
send_cron_notify () {
	if [[ -f $file_upcron_notify ]]; then
		send_notify "更新定时任务" "$(cat $file_upcron_notify)"
		rm $file_upcron_notify
	fi
}

## 新增定时任务
add_cron () {
	for add_cron_list in $(diff $file_scripts_list $scripts_list_new | grep "+" | grep -v '@\|scripts.list' | sed 's/+//g'); do
		if [[ -n $add_cron_list ]]; then
			add_task_name=$(echo $add_cron_list | awk -F "/" '{print $NF}')
			add_task_name=${add_task_name%%.*}
			add_task_word=$(sed -n '/^const \$/p' $add_cron_list | awk -F '"' '{print $2}')
			if [[ -z $add_task_word ]]; then
				add_task_word=$(sed -n '/^const \$/p' $add_cron_list | awk -F "'" '{print $2}')
			fi
			
			# 提取并验证cron
			add_task_cron=$(cat $add_cron_list | grep -oE '[0-9*,-/]{1,}\ [0-9*,-/]{1,}\ [0-9*,-?/LWC]{1,}\ [0-9*,-/]{1,}\ [0-9*,-?/LC#]{1,}' | head -n 1)
			add_task_cron_min=$(echo $add_task_cron | awk '{print $1}')
			expr $add_task_cron_min + 1 &>/dev/null
			if [ $? -eq 0 ] && [[ $add_task_cron_min -gt 59 ]]; then
				add_task_cron=""
			fi
			add_task_cron_hour=$(echo $add_task_cron | awk '{print $2}')
			expr $add_task_cron_hour + 1 &>/dev/null
			if [ $? -eq 0 ] && [[ $add_task_cron_hour -gt 23 ]]; then
				add_task_cron=""
			fi
			add_task_cron_day=$(echo $add_task_cron | awk '{print $3}')
			expr $add_task_cron_day + 1 &>/dev/null
			if [ $? -eq 0 ] && [[ $add_task_cron_day -gt 31 ]]; then
				add_task_cron=""
			fi
			add_task_cron_month=$(echo $add_task_cron | awk '{print $4}')
			expr $add_task_cron_month + 1 &>/dev/null
			if [ $? -eq 0 ] && [[ $add_task_cron_month -gt 12 ]]; then
				add_task_cron=""
			fi
			add_task_cron_week=$(echo $add_task_cron | awk '{print $NF}')
			expr $add_task_cron_week + 1 &>/dev/null
			if [ $? -eq 0 ] && [[ $add_task_cron_week -gt 7 ]]; then
				add_task_cron=""
			fi

			if [[ -z $add_task_cron || -z $add_task_word ]]; then
				echo -e "添加任务 $add_task_word 失败，file：$add_task_name"
				echo -e "添加任务 $add_task_word 失败，file：$add_task_name" >> $file_upcron_notify
			else
				echo -e "# $add_task_word" >> $file_crontab_user
				if [[ $add_task_cron_min == 59 || $add_task_cron_min == 0 || $add_task_cron_min == 29 || $add_task_cron_min == 30 ]]; then
					echo -e "$add_task_cron task $add_task_name now" >> $file_crontab_user
				else
					echo -e "$add_task_cron task $add_task_name" >> $file_crontab_user
				fi
				echo -e "添加任务 $add_task_word 成功，file：$add_task_name"
				echo -e "添加任务 $add_task_word 成功，file：$add_task_name" >> $file_upcron_notify
			fi
		fi
	done
}

## 删除失效任务
del_cron () {
	for del_cron_list in $(diff $file_scripts_list $scripts_list_new | grep "-" | grep -v '@\|scripts.list' | sed 's/-//g'); do
		if [[ -n $del_cron_list ]]; then
			del_task_name=$(echo $del_cron_list | awk -F "/" '{print $NF}')
			del_task_name=${del_task_name%%.*}
			del_task_line=$(cat $file_crontab_user | grep -n "\<$del_task_name\>" | cut -d ":" -f 1)
			if [[ -n $del_task_line ]]; then
				del_word_line=$((del_task_line-1))
				del_task_word=$(sed -n "${del_word_line}p" $file_crontab_user | cut -d " " -f 2-)
				sed -i "${del_word_line},${del_task_line}d" $file_crontab_user
				echo -e "删除失效任务 ${del_task_word} file：${del_task_name}"
				echo -e "删除失效任务 ${del_task_word} file：${del_task_name}" >> $file_upcron_notify
			else
				echo -e "被移除脚本 $del_task_name 并无定时任务.."
				echo -e "被移除脚本 $del_task_name 并无定时任务.." >> $file_upcron_notify
			fi		
		fi
	done
}

set_config
if [ -d $dir_scripts/.git ];then
	git_pull_scripts $url_scripts ${dir_scripts}
else
	git_clone_scripts $url_scripts ${dir_scripts}
fi
if [[ ! -f $filepath2 || $filepath1 -nt $filepath2 ]];then
	cp_joyreward_scripts
fi
update_own_raw
create_scripts_list
del_cron
add_cron
update_scripts_list
send_cron_notify
update_crontab

exit 0
