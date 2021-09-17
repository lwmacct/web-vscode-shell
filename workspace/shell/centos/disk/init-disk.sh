#!/bin/bash
# 格式化并挂载磁盘,适配 centos
# 技术支持 QQ1713829947 http://lwm.icu
# 2021-3-10 20:16:06

__init_args() {
    # 取得系统盘所在盘符
    _rootfs_disk=$(lsblk 2>/dev/null | grep '\s/$' -B10 | tac | grep '\sdisk' | head -1 | awk '{print $1}')
    _is_mkfs=$(echo "$@" | grep -Eo 'mkfs=\S*?' | awk -F '=' '{print $NF}')

}

__disk_umount() {
    _all_disk=$(lsblk -dn | grep -E 'sd|vd|nvme' | awk '{print "/dev/"$1}' | grep -v "$_rootfs_disk$")

    for _item in $_all_disk; do
        _subarea=$(blkid | grep "$_item" | awk -F ":" '{print $1}')
        echo "开始卸载磁盘: $_item "
        for _item2 in $_subarea; do
            lsof -t "$_item2" | awk '{print "kill -9 " $1}' | sh # 杀死占用
            lsof -t "$_item2" | awk '{print "kill -9 " $1}' | sh # 杀死占用
            umount -f "$_item2" >/dev/null 2>&1
        done
    done
}

__formatting() {
    # 循环检测猕猴桃磁盘
    echo -e "\n识别系统盘为: $_rootfs_disk 开始初始化磁盘..."
    _all_disk=$(lsblk -dn | grep -E 'sd|vd|nvme' | awk '{print "/dev/"$1}' | grep -v "$_rootfs_disk$")
    for _item in $_all_disk; do
        # 如果磁盘未格式化
        _is_label=$(blkid | grep -Ec "$_item"'.* LABEL="(kuaicdn|data)"')

        # 如果传递的参数标 mkfs 为 yes 那么将直接格式化
        if [[ "$_is_mkfs" == "yes" ]]; then
            _is_label=0
        fi

        if ((_is_label != 1)); then
            dd if=/dev/zero of="$_item" bs=1M count=128 >/dev/null 2>&1
            parted -s "$_item" mklabel gpt
            parted -s "$_item" mkpart lwmacct xfs 0% 100%
            echo '磁盘: '"$_item 正在格式化..."

            # 判断是否为 nvme盘,以便设置识别一个分区名
            _is_nvme=$(echo "$_item" | grep -c "nvme")
            if ((_is_nvme == 1)); then
                _p="p1"
            else
                _p="1"
            fi
            mkfs.xfs -f "${_item}${_p}" >/dev/null 2>&1
            xfs_admin -L data "${_item}${_p}" >/dev/null 2>&1
        else
            echo -e "磁盘: $_item 已是数据盘，无需格式化"
        fi
    done
}

__mount() {
    sed -in-place -e '\/disk.*/d' /etc/fstab
    sed -in-place -e '\/data[0-9]\{1,2\}.*/d' /etc/fstab

    blkid -s "LABEL" -s "UUID" -s 'TYPE' | grep -E "kuaicdn|data" | grep -Eo '[0-9a-z-]{36}.*' | sed 's/"//g' | sed 's/TYPE=//g' | awk -F "-| " '{print "echo \"UUID=" $1"-"$2"-"$3"-"$4"-"$5 " /disk/"$1" "$6" defaults,noatime,nodiratime  0 0\" >> /etc/fstab; mkdir -p /disk/"$1}' | sh
    mount -a
}

# 解决读不到UUID的磁盘挂载
__write_file_mount_no_uuid() {
    cat >/etc/init.d/mount_no_uuid <<-'AEOF'
#!/usr/bin/env bash
# chkconfig: 2345 10 90
__main() {

    _lsblk=$(lsblk)
    _rootfs_disk=$(lsblk | grep '\s/$' -B10 | tac | grep '\sdisk' | head -1 | awk '{print $1}')
    _disk_label=$(blkid -s "LABEL" | grep -E 'LABEL="(kuaicdn|data)"')
    _all_disk=$(lsblk -dn | grep -E 'sd|vd|nvme' | awk '{print $1}' | grep -v "$_rootfs_disk$")

    for item in $_all_disk; do
        _is=$(echo "$_disk_label" | grep -c "$item")
        if ((_is == 0)); then
            _part=$(echo "$_lsblk" | grep -o "$item.*part\s" | head -1 | awk '{print $1}') # 得到分区
            _mount_dir=$(echo "$_part" | md5sum | cut -c1-8)
            mkdir -p "/disk/$_mount_dir"
            mount -o noatime -o nodiratime /dev/"$_part" "/disk/$_mount_dir" 2>/dev/null
        fi
    done
}
__main
AEOF
    chmod 777 /etc/init.d/mount_no_uuid
    chkconfig --add mount_no_uuid
    chkconfig mount_no_uuid on
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
__write_file_mount_no_uuid
/etc/init.d/mount_no_uuid

echo '************** 磁盘初始化结束 **************'

__help() {
    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/disk/init-disk.sh)"
    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/disk/init-disk.sh)" x mkfs=yes

    cat >/tmp/items <<-'AEOF'

该脚本在以下文章中又有用,调整路径时需要及时更新
https://www.yuque.com/uuu/centos/disk-format

AEOF
}
