## 目录
dir_log=$dir_shell/log
dir_scripts=$dir_shell/scripts
dir_raw=$dir_shell/raw
dir_config=$dir_shell/config
dir_sample=$dir_shell/sample
dir_list_tmp=$dir_log/.tmp

## 文件
file_config=$dir_config/config.sh
file_config_sample=$dir_sample/config.sample.sh
file_crontab_user=$dir_config/crontab.list
file_scripts_list=$dir_config/scripts.list
file_upcron_notify=$dir_list_tmp/upcron_notify.log
scripts_list_old=$dir_list_tmp/scripts.list.old
scripts_list_new=$dir_list_tmp/scripts.list.new

## 软链接及对应文件
link_name=(
	update
	task
	rmlog
)
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

## 创建软连接的子函数，$1：软连接文件路径，$2：要连接的对象
link_shell_sub () {
    local link_path="$1"
    local original_path="$2"
    if [ ! -L $link_path ] || [[ $(readlink -f $link_path) != $original_path ]]; then
        rm -f $link_path 2>/dev/null
        ln -sf $original_path $link_path
    fi
}

## 创建软链接
link_shell () {
	for ((i=0; i<${#link_name[*]}; i++)); do
		link_shell_sub "/usr/local/bin/${link_name[i]}" "$dir_shell/${original_name[i]}"
	done
}

## 设置权限子函数，$1：文件绝对路径
shell_chmod_sub () {
	local file=$1
	if [ ! -x $file ]; then
		chmod +x $file
	fi
}

## 设置权限
shell_chmod () {
	for ((i=0; i<${#original_name[*]}; i++)); do
		shell_chmod_sub "$dir_shell/${original_name[i]}"
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
    if [[ $(cat $list_crontab_user) != $(crontab -l) ]]; then
        crontab $list_crontab_user
    fi
}
