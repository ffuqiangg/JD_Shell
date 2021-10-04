#!/usr/bin/env bash

## 路径
dir_shell=$(dirname $(readlink -f "$0"))

## 导入变量，函数
. $dir_shell/share.sh

set_config
update

exit 0
