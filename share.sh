dir_log=$dir_shell/log
dir_scripts=$dir_shell/scripts
dir_raw=$dir_shell/raw
dir_config=$dir_shell/config
dir_sample=$dir_shell/sample
dir_list_tmp=$dir_shell/.tmp
file_config=$dir_config/config.sh
file_config_sample=$dir_sample/config.sample.sh
file_crontab_user=$dir_config/crontab.list
file_upcron_notify=$dir_list_tmp/upcron_notify.log
scripts_list_old=$dir_list_tmp/scripts.list.old
scripts_list_new=$dir_list_tmp/scripts.list.new

original_name=(
    update.sh
    task.sh
    rmlog.sh
)

make_dir () {
    local dir=$1
    [ ! -d $dir ] && mkdir -p $dir
}

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

shell_chmod () {
    for ((i=0; i<${#original_name[*]}; i++)); do
        if [[ ! -x $dir_shell/${original_name[i]} ]]; then
            chmod +x $dir_shell/${original_name[i]}
        fi
    done
}

send_notify () {
    title=$(echo $1 | sed 's/-/_/g')    #标题
    msg=$(echo -e $2)                   #正文
    node $dir_shell/notify.js "$title" "$msg"
}

update_crontab () {
    if [[ $(cat $file_crontab_user) != $(crontab -l) ]]; then
        crontab $file_crontab_user
    fi
}

make_random () {
    local random_max=$1   #最大值
    local random_min=$2   #最小值
    local random_min=${random_min:=1}
    rem_num=$(($random_max - $random_min + 1))
    random_num=$((RANDOM % $rem_num + $random_min))
    echo $random_num
}

create_list () {
    local dir=$1         #目录
    local filetype=$2    #后缀
    local filelist=$3    #输出文件
    ls $dir/*.$filetype > $filelist
}
