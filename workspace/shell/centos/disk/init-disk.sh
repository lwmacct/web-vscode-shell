#!/bin/bash
# 格式化并挂载磁盘,适配 centos
# 技术支持 QQ1713829947 http://lwm.icu
# 2021-3-10 20:16:06

__init_args() {
    _rootfs_partition=$(lsblk | grep '/boot$' | awk '{print $1}' | grep -o '[a-z]*')
    _full_formatting=0
    if [[ "$0" == "full" ]]; then
        _full_formatting=1
    fi
}

__disk_umount() {
    echo '开始磁盘卸载....'
    _disks=$(lsblk -dn | grep -E 'sd|vd|nvme' | awk '{print "/dev/"$1}' | grep -v "$_rootfs_partition.*")

    echo "需要卸载的磁盘-$_disks"
    for _item in $_disks; do
        _subarea=$(blkid | grep $_item | awk -F ":" '{print $1}')
        # 杀死占用
        echo "开始卸载磁盘: $_item 分区: $_subarea"
        for _item2 in $_subarea; do
            echo "lsof -t $_item2" | sh | awk '{print "kill -9 "$0}' | sh
            echo "lsof -t $_item2" | sh | awk '{print "kill -9 "$0}' | sh
            echo "lsof -t $_item2" | sh | awk '{print "kill -9 "$0}' | sh
            umount -f $_item2 >/dev/null 2>&1
        done
    done
    sync
    echo '卸载完毕'
}

__formatting() {
    # 循环检测猕猴桃磁盘
    echo '识别系统盘为: '$_rootfs_partition' 开始初始化磁盘...'
    _disks=$(lsblk -dn | grep -E 'sd|vd|nvme' | grep -v "$_rootfs_partition.*" | awk '{print $1}')
    for _item in $_disks; do
        # 如果磁盘未格式化
        _is_havue=$(blkid | grep -c "$_item"'.* LABEL="kuaicdn"')
        # 如果标记 curl 参数标记为 full 那么将直接格式化
        if ((_full_formatting == 1)); then
            _is_havue=0
        fi
        if ((_is_havue != 1)); then
            # 兼容旧版Dcache一键格式化磁盘,保留数据
            _monoblock=$(blkid | grep -c "$_item:.* UUID.*xfs")
            if ((_monoblock == 1)); then
                echo "检测到磁盘 ${_item} 为整盘 xfs,执行打标记并略过格式化..."
                xfs_admin -L kuaicdn /dev/"${_item}" >/dev/null 2>&1
                continue
            fi
            dd if=/dev/zero of=/dev/"$_item" bs=512K count=1 >/dev/null 2>&1
            parted -s /dev/"$_item" mklabel gpt
            parted -s /dev/"$_item" mkpart kuaicdn xfs 0% 100%
            echo '磁盘: '"$_item 正在格式化..."
            _is_nvme=$(echo "$_item" | grep -c "nvme")
            if ((_is_nvme == 1)); then
                _p="p1"
            else
                _p="1"
            fi
            mkfs.xfs -f /dev/"${_item}${_p}" >/dev/null 2>&1
            xfs_admin -L kuaicdn /dev/"${_item}${_p}" >/dev/null 2>&1
        else
            echo -e "磁盘: $_item 已是 KuaiCDN 数据盘，无需格式化"
        fi
    done
}

__mount() {
    sed -in-place -e '\/tmp\/disk.*/d' /etc/fstab
    sed -in-place -e '\/kuaicdn\/disk.*/d' /etc/fstab    # 兼容2020年早期挂盘路径
    sed -in-place -e '\/data[0-9]\{1,2\}.*/d' /etc/fstab # 兼容Dcache自带格盘脚本

    blkid -s "LABEL" -s "UUID" -s 'TYPE' | grep kuaicdn | grep -Eo '[0-9a-z-]{36}.*' | sed 's/"//g' | sed 's/TYPE=//g' | awk -F "-| " '{print "echo \"UUID=" $1"-"$2"-"$3"-"$4"-"$5 " /tmp/disk/"$1" "$6" defaults,noatime,nodiratime  0 0\" >> /etc/fstab; mkdir -p /tmp/disk/"$1}' | sh
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
