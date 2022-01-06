#!/usr/bin/env bash

## 路径
dir_shell=$(dirname $(readlink -f "$0"))

## 导入配置文件，通用函数变量
. $dir_shell/share.sh
. $file_config

## 使用说明
usage () {
    echo "task 命令使用说明："
    echo "task <js_name>       # 运行脚本，如设置了延迟且不在0-2、29-31、58分内，将随机延迟一定秒数"
    echo "task <js_name> now   # 立即运行脚本"
}

## 随机延迟执行函数
random_delay () {
		local delay_second
    if [[ $RandomMax ]] && [[ $RandomMax -gt 0 ]]; then
        local current_min=$(date "+%-M")
        if [[ $current_min -gt 2 && $current_min -lt 29 ]] || [[ $current_min -gt 31 && $current_min -lt 58 ]]; then
            delay_second=$(make_random $RandomMax $RandomMin)
            echo -e "\n命令未添加 \"now\"，随机延迟 $delay_second 秒后再执行任务，如需立即终止，请按 CTRL+C...\n"
            sleep $delay_second
        fi
    fi
}

## 正常运行脚本
run_normal () {
    local task_name=$1
    if [[ -f $dir_scripts/$task_name.js ]]; then
        make_dir $dir_log/$task_name
        node $dir_scripts/$task_name.js 2>&1 | tee $dir_log/$task_name/$(date +%Y-%m-%d-%H-%M-%S).log
    else
        echo "脚本文件 $dir_scripts/$task_name.js 不存在"
    fi
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
