#!/usr/bin/env bash

## 文件路径、脚本网址
dir_shell=$(dirname $(readlink -f "$0"))
url_scripts='https://github.com/shufflewzc/faker2.git'

## 导入变量函数，配置文件
. $dir_shell/share.sh
. $file_config

## 创建软链接
link_shell
shell_chmod

## 在日志中记录时间与路径
record_time () {
    echo "
--------------------------------------------------------------

系统时间：$(date "+%Y-%m-%d %H:%M:%S")

脚本根目录：$dir_shell

jd_scripts目录：$dir_scripts

raw脚本目录：$dir_raw
"
}

## 使用帮助
usage () {
    echo "使用帮助："
    echo "update         # 更新所有脚本，添加定时任务"
    echo "update scripts # 只更新jd_scripts脚本"
    echo "update cron    # 更新crontab任务"
    echo "update npm     # 按package.json更新依赖"
}

## npm install
npm_install () {
    local dir_current=$(pwd)
    [ -s $dir_sample/package.json ] && package_old=$(cat $dir_sample/package.json)
    wget -q --no-check-certificate -O $dir_sample/package.json https://raw.githubusercontent.com/ffuqiangg/JD_Shell/main/sample/package.json
    if [[ $? -eq 0 ]]; then
        package_new=$(cat $dir_sample/package.json)
        if [[ ! -d $dir_scripts/node_modules || "$package_old" != "$package_new" ]]; then
            cp -f $dir_sample/package.json $dir_scripts/package.json
            cd $dir_scripts
            npm install
            cd $dir_current
        fi
    fi  
}

## 克隆脚本，$1：仓库地址，$2：仓库保存路径，$3：分支（可省略）
git_clone_scripts () {
    local url=$1
    local dir=$2
    local branch=$3
    [[ $branch ]] && cmd="-b $branch "
    git clone $cmd $url $dir
}

## 更新脚本，$1：仓库保存路径
git_pull_scripts () {
    local dir_work=$1
    local dir_current=$(pwd)
    cd $dir_work
    git reset --hard && git pull
    cd $dir_current
}

## 更新scripts
update_scripts () {
    # 首次运行使用sample目录文件，之后运行于脚本更新前生成
    if [[ -f $dir_sample/scripts.list.old ]]; then
        mv $dir_sample/scripts.list.old $scripts_list_old
    else
        create_list "$dir_scripts" js "$scripts_list_old"
    fi

    # 更新或克隆脚本
    if [ -d $dir_scripts/.git ];then
        git_pull_scripts ${dir_scripts}
    else
        git_clone_scripts $url_scripts ${dir_scripts}
    fi

    if [[ $exit_status -eq 0 ]]; then
        echo -e "\n更新$dir_scripts成功...\n"
    else
        echo -e "\n更新$dir_scripts失败，请检查原因...\n"
    fi
}

## 复制宠汪汪兑换脚本并修改变量
cp_joyreward_scripts () {
    if [[ ! -f $dir_scripts/jd_joy_reward2.js || $dir_scripts/jd_joy_reward.js -nt $dir_scripts/jd_joy_reward2.js ]];then
        cp $dir_scripts/jd_joy_reward.js $dir_scripts/jd_joy_reward2.js
        sed -i 's/JD_JOY_REWARD_NAME/JD_JOY_REWARD_NAME2/g' $dir_scripts/jd_joy_reward2.js
    fi
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

## 新增定时任务
add_cron () {
    echo "-----------------------新增任务---------------------"
    echo -n "-----------------------新增任务---------------------\n" >> $file_upcron_notify
    for add_cron_list in $(diff $scripts_list_old $scripts_list_new | grep ">" | sed 's/> //g'); do
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
                echo "【$add_task_word】 $add_task_name.js 任务添加失败"
                echo -n "【$add_task_word】 $add_task_name.js 任务添加失败\n" >> $file_upcron_notify
            else
                task_name=$(grep -n "\<$add_task_name\>" $file_crontab_user)
                if [[ -z $task_name ]]; then
                    echo "# $add_task_word" >> $file_crontab_user
                    echo "$add_task_cron task $add_task_name" >> $file_crontab_user
                    echo "【$add_task_word】 $add_task_name.js 任务添加成功"
                    echo -n "【$add_task_word】 $add_task_name.js 任务添加成功\n" >> $file_upcron_notify
                else
                    echo "【$add_task_word】 $add_task_name.js 任务已存在"
                    echo -n "【$add_task_word】 $add_task_name.js 任务已存在\n" >> $file_upcron_notify
                fi
            fi
        fi
    done
}

## 删除失效任务
del_cron () {
    echo "-----------------------删除任务---------------------"
    echo -n "-----------------------删除任务---------------------\n" >> $file_upcron_notify
    for del_cron_list in $(diff $scripts_list_old $scripts_list_new | grep "<" | sed 's/< //g'); do
        if [[ -n $del_cron_list ]]; then
            del_task_name=$(echo $del_cron_list | awk -F "/" '{print $NF}')
            del_task_name=${del_task_name%%.*}
            del_task_line=$(cat $file_crontab_user | grep -n "\<$del_task_name\>" | cut -d ":" -f 1)
            if [[ -n $del_task_line ]]; then
                del_word_line=$((del_task_line-1))
                del_task_word=$(sed -n "${del_word_line}p" $file_crontab_user | cut -d " " -f 2-)
                sed -i "${del_word_line},${del_task_line}d" $file_crontab_user
                echo "【$del_task_word】 $del_task_name.js 任务移除成功"
                echo -n "【$del_task_word】 $del_task_name.js 任务移除成功\n" >> $file_upcron_notify
            else
                echo "【$del_task_name】 $del_task_name.js 无定时任务.."
                echo -n "【$del_task_name】 $del_task_name.js 无定时任务..\n" >> $file_upcron_notify
            fi      
        fi
    done
}

## 修改定时任务
update_cron () {
    create_list "$dir_scripts" js "$scripts_list_new"
    del_cron
    add_cron
}

## 更新定时任务通知
send_cron_notify () {
    if [[ -f $file_upcron_notify ]]; then
        send_notify "更新定时任务" "$(cat $file_upcron_notify)"
        rm -f $file_upcron_notify
    fi
}

## 修复crontab
fix_crontab () {
    if [[ $JD_DIR ]]; then
        perl -i -pe "s|( ?&>/dev/null)+||g" $file_crontab_user
        update_crontab
    fi
}

main () {
    case $# in
        1)
            case $1 in
                scripts)
                    record_time
                    update_scripts
                    cp_joyreward_scripts
                    ;;
                cron)
                    update_crontab
                    ;;
                npm)
                    npm_install
                    ;;
                *)
                    usage
                    ;;
            esac
            ;;
        0)
            record_time
            update_scripts
            npm_install
            cp_joyreward_scripts
            update_own_raw
            update_cron
            send_cron_notify
            fix_crontab
            ;;
        *)
            usage
            ;;
    esac
    exit 0
}

main "$@"
