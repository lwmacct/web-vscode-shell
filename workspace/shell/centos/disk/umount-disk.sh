#!/bin/bash
# 格式化并挂载磁盘,适配 centos
# 技术支持 QQ1713829947 http://lwm.icu
# 2021-3-10 20:16:06

__init_args() {
    # 取得系统盘所在盘符
    _rootfs_disk=$(lsblk 2>/dev/null | grep '\s/$' -B10 | tac | grep '\sdisk' | head -1 | awk '{print $1}')

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

__init_args "$@"
__disk_umount

echo '************** 磁盘初始化结束 **************'

__help() {

    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/disk/umount-disk.sh)"

    cat >/tmp/items <<-'AEOF'

该脚本在以下文章中又有用,调整路径时需要及时更新
https://www.yuque.com/uuu/centos/disk-format

AEOF
}
