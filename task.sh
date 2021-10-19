#!/usr/bin/env bash

## 路径
dir_shell=$(dirname $(readlink -f "$0"))

## 导入配置文件，通用函数变量
. $dir_shell/share.sh
. $file_config

## 记录时间
write_header () {
	echo "
------------------------------------------------

系统时间：$(date "+%Y-%m-%d %H:%M:%S")

一周京豆收支
"
}

## 使用说明
usage () {
    echo "task 命令使用说明："
    echo "task <js_name>       # 运行脚本，如设置了延迟且不在0-2、29-31、59分内，将随机延迟一定秒数"
    echo "task <js_name> now   # 立即运行脚本"
    echo "task week            # 一周京豆收支统计"
}

## 随机延迟执行函数
random_delay () {
	local random_delay_max=$RandomMax
	local random_delay_min=$RandomMin
	if [[ $random_delay_max ]] && [[ $random_delay_max -gt 0 ]]; then
		local current_min=$(date "+%-M")
		if [[ $current_min -gt 2 && $current_min -lt 29 ]] || [[ $current_min -gt 31 && $current_min -lt 59 ]]; then
			delay_second=$(make_random $random_delay_max $random_delay_min)
			echo -e "\n命令未添加 \"now\"，随机延迟 $delay_second 秒后再执行任务，如需立即终止，请按 CTRL+C...\n"
			sleep $delay_second
		fi
	fi
}

## 正常运行脚本
run_normal () {
	local task_name=$1
	make_dir $dir_log/$task_name
	node $dir_scripts/$task_name.js 2>&1 | tee $dir_log/$task_name/$(date +%Y-%m-%d-%H-%M-%S).log
}

## 多合一签到脚本函数
run_bean_sign () {
	local dir_current=$(pwd)
	local task_name=$1
	make_dir $dir_log/$task_name
	cd $dir_scripts
	node $task_name.js 2>&1 | tee $dir_log/$task_name/$(date +%Y-%m-%d-%H-%M-%S).log
	cd $dir_current
}

## 一周收支统计
bean_week () {
	local sumin=0
	local sumout=0
	write_header
	for day_num in {0..6}; do
		local bean_log=$dir_log/jd_bean_change_new/$(date -d "$day_num day ago" +"%F")-*.log
		cat $bean_log &>/dev/null
		if [[ $? -gt 0 ]]; then
			break
		fi
		local yester_day=$(date -d "$(($day_num + 1)) day ago" +"%F")
		local beanin=$(sed -n '/^昨日收入/p' $bean_log | grep -oE '[0-9]{1,}')
		local beanout=$(sed -n '/^昨日支出/p' $bean_log | grep -oE '[0-9]{1,}')
		echo -n "$yester_day | ∧ ${beanin}京豆 ∨ ${beanout}京豆\n" >> $file_bean_week
		echo "$yester_day | ∧ ${beanin}京豆 ∨ ${beanout}京豆"
		sumin=$(($sumin + $beanin))
		sumout=$(($sumout + $beanout))
	done
	echo -n "---------------------------------\n" >> $file_bean_week
	echo "---------------------------------"
	echo -n "【总计】 ∧ ${sumin}京豆 ∨ ${sumout}京豆\n" >> $file_bean_week
	echo "【总计】 ∧ ${sumin}京豆 ∨ ${sumout}京豆"
	send_notify "一周京豆收支" "$(cat $file_bean_week)"
	rm -f $file_bean_week
}

main () {
	case $# in
		0)
			usage
			;;
		1)
			case $1 in
				jd_bean_sign)
					run_bean_sign $1
					;;
				week)
					bean_week
					;;
				*)
					random_delay
					run_normal $1
					;;
			esac
			;;
		2)
			case $2 in
				now)
					run_normal $1
					;;
				*)
					echo -e "\n命令输入错误...\n"
					usage
					;;
			esac
			;;
		*)
			echo -e "\n命令过多...\n"
			usage
			;;
	esac
}

main "$@"
