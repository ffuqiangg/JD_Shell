#!/usr/bin/env bash

## 路径
dir_shell=/jd
url_scripts=https://github.com/shufflewzc/faker2.git

## 导入函数变量
. $dir_shell/share.sh

link_shell
set_config
git clone $url_scripts $dir_scripts 
update_crontab
