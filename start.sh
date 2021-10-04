#!/usr/bin/env bash

## 路径
dir_shell=/jd

## 导入函数变量
. $dir_shell/share.sh

link_shell
set_config
update_crontab

exec "$@"
