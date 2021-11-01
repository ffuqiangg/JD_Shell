## 目录
dir_log=$dir_shell/log
dir_scripts=$dir_shell/scripts
dir_raw=$dir_shell/raw
dir_config=$dir_shell/config
dir_sample=$dir_shell/sample
dir_list_tmp=$dir_shell/.tmp

## 文件
file_config=$dir_config/config.sh
file_config_sample=$dir_sample/config.sample.sh
file_crontab_user=$dir_config/crontab.list
file_scripts_list=$dir_config/scripts.list
file_upcron_notify=$dir_list_tmp/upcron_notify.log
scripts_list_old=$dir_list_tmp/scripts.list.old
scripts_list_new=$dir_list_tmp/scripts.list.new
file_bean_week=$dir_list_tmp/bean.week.log

## 软链接对应文件
original_name=(
    update.sh
    task.sh
    rmlog.sh
)

## 创建目录，$1：目录绝对路径
make_dir () {
    local dir=$1
    [ ! -d $dir ] && mkdir -p $dir
}

## 创建/修复 软链接
link_shell () {
    for ((i=0; i<${#original_name[*]}; i++)); do
        link_name=/usr/local/bin/${original_name[i]%%.*}
        shell_name=$dir_shell/${original_name[i]}
        if [ ! -L $link_name ] || [[ $(readlink -f $link_name) != $shell_name ]]; then
            rm -f $link_name 2>/dev/null
            ln -sf $shell_name $link_name
        fi
    done
}

## 设置/修复 权限
shell_chmod () {
    for ((i=0; i<${#original_name[*]}; i++)); do
        if [[ ! -x $dir_shell/${original_name[i]} ]]; then
            chmod +x $dir_shell/${original_name[i]}
        fi
    done
}

## 发送通知 $1：标题，$2：正文
send_notify () {
    title=$(echo $1 | sed 's/-/_/g')
    msg=$(echo -e $2)
    node $dir_shell/notify.js "$title" "$msg"
}

## 更新crontab
update_crontab () {
    if [[ $(cat $file_crontab_user) != $(crontab -l) ]]; then
        crontab $file_crontab_user
    fi
}

## 生成随机数 $1：最大值 $2：最小值(缺省值1)
make_random () {
    local random_max=$1
    local random_min=$2
    local random_min=${random_min:=1}
    local divi=$(($random_max - $random_min +1))
    random_num=$((RANDOM % $divi + $random_min))
    echo $random_num
}

## 生成文件列表 $1：所在目录 $2：文件后缀 $3：存放列表文件
create_list () {
    local dir=$1
    local filetype=$2
    local filelist=$3
    ls $dir/*.$filetype > $filelist
}
