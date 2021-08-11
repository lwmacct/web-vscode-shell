#!/bin/bash
# 格式化并挂载磁盘,适配 centos
# 技术支持 QQ1713829947 http://lwm.icu
# 2021-3-10 20:16:06

__init_args() {

    # 取得系统盘所在盘符
    _rootfs_disk=$(lsblk | grep '\s/$' -B10 | tac | grep '\sdisk' | head -1 | awk '{print $1}')

    _is_mkfs=$(echo "$@" | grep -Eo 'mkfs=\S*?' | awk -F '=' '{print $NF}')

}

__disk_umount() {
    echo '开始磁盘卸载....'
    _all_disk=$(lsblk -dn | grep -E 'sd|vd|nvme' | awk '{print "/dev/"$1}' | grep -v "$_rootfs_disk.*")

    echo -e "需要卸载的磁盘\n $_all_disk"
    for _item in $_all_disk; do
        _subarea=$(blkid | grep $_item | awk -F ":" '{print $1}')
        # 杀死占用
        echo "开始卸载磁盘: $_item 分区: $_subarea"
        for _item2 in $_subarea; do
            lsof -t "$_item2" | awk '{print "kill -9 " $1}' | sh
            lsof -t "$_item2" | awk '{print "kill -9 " $1}' | sh
            umount -f "$_item2" >/dev/null 2>&1
        done
    done
    echo '卸载完毕'
}

__formatting() {
    # 循环检测猕猴桃磁盘
    echo "识别系统盘为: $_rootfs_disk 开始初始化磁盘..."
    _all_disk=$(lsblk -dn | grep -E 'sd|vd|nvme' | grep -v "$_rootfs_disk.*" | awk '{print $1}')
    for _item in $_all_disk; do
        # 如果磁盘未格式化
        _is_label=$(blkid | grep -c "$_item"'.* LABEL="(kuaicdn|data)"')

        # 如果传递的参数标 mkfs 为 yes 那么将直接格式化
        if [[ "$_is_mkfs" == "yes" ]]; then
            _is_label=0
        fi

        if ((_is_label != 1)); then

            dd if=/dev/zero of=/dev/"$_item" bs=512K count=1 >/dev/null 2>&1
            parted -s /dev/"$_item" mklabel gpt
            parted -s /dev/"$_item" mkpart lwmacct xfs 0% 100%
            echo '磁盘: '"$_item 正在格式化..."

            # 判断是否为 nvme盘,以便设置识别一个分区名
            _is_nvme=$(echo "$_item" | grep -c "nvme")
            if ((_is_nvme == 1)); then
                _p="p1"
            else
                _p="1"
            fi
            mkfs.xfs -f /dev/"${_item}${_p}" >/dev/null 2>&1
            xfs_admin -L data /dev/"${_item}${_p}" >/dev/null 2>&1
        else
            echo -e "磁盘: $_item 已是数据盘，无需格式化"
        fi
    done
}

__mount() {
    sed -in-place -e '\/tmp\/disk.*/d' /etc/fstab
    sed -in-place -e '\/data[0-9]\{1,2\}.*/d' /etc/fstab

    blkid -s "LABEL" -s "UUID" -s 'TYPE' | grep kuaicdn | grep -Eo '[0-9a-z-]{36}.*' | sed 's/"//g' | sed 's/TYPE=//g' | awk -F "-| " '{print "echo \"UUID=" $1"-"$2"-"$3"-"$4"-"$5 " /disk/"$1" "$6" defaults,noatime,nodiratime  0 0\" >> /etc/fstab; mkdir -p /disk/"$1}' | sh
    mount -a
}

__init_yum() {
    # 检查并安装常用工具
    _is_install=$(yum list installed lsof | grep -Ec 'lsof')
    if ((_is_install != 1)); then
        curl -Lo /tmp/lsof.rpm https://mirrors.aliyun.com/centos/7/os/x86_64/Packages/lsof-4.87-6.el7.x86_64.rpm && echo 'rpm -i /tmp/lsof.rpm' | sh
        rm -rf /tmp/lsof.rpm
    fi
}

__init_args "$@"
__init_yum
__disk_umount
__formatting
__mount

echo '磁盘初始化结束'
sync

__help() {
    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/disk/init-disk.sh)"
    cat >/tmp/items <<-'AEOF'

该脚本在以下文章中又有用,调整路径时需要及时更新
https://www.yuque.com/uuu/centos/disk-format

AEOF
}
