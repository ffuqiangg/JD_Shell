#!/usr/bin/env bash

## 路径
dir_shell=$(dirname $(readlink -f "$0"))

# 导入变量函数
. $dir_shell/share.sh
. $file_config

## 删除运行js脚本的旧日志
remove_js_log () {
  local log_full_path_list=$(ls -l $dir_log/*/*.log | grep -v "bot" | awk '{print $9}')
  local diff_time
  for log in $log_full_path_list; do
    local log_date=$(echo $log | awk -F "/" '{print $NF}' | cut -c 1-10)   #文件名比文件属性获得的日期要可靠
    diff_time=$(($(date +%s) - $(date +%s -d "$log_date")))
    [[ $diff_time -gt $((${RmLogDaysAgo} * 86400)) ]] && rm -vf $log
  done
}

## 删除空文件夹
remove_empty_dir () {
  cd $dir_log
  for dir in $(ls); do
    if [ -d $dir ] && [[ -z $(ls $dir) ]]; then
      rm -rf $dir
    fi
  done
}

## 运行
if [[ ${RmLogDaysAgo} ]]; then
  echo -e "查找旧日志文件中...\n"
  remove_js_log
  remove_empty_dir
  echo -e "删除旧日志执行完毕\n"
fi

exit 0
