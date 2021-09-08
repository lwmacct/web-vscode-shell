#!/bin/bash
# 格式化并挂载磁盘,适配 centos
# 技术支持 QQ1713829947 http://lwm.icu
# 2021-3-10 20:16:06

docker pull registry.cn-hangzhou.aliyuncs.com/lwmacct/pppoe:manage-v2.3
docker pull registry.cn-hangzhou.aliyuncs.com/lwmacct/pppoe:call-v2.3

__update_to_Key_value_pair() {
    _path_account=/data/docker-data/pppoe/account.txt
    _path_format=/data/docker-data/pppoe/format.tmp
    is_kv=$(cat "$_path_account" | grep 'account=' -c)
    if ((is_kv == 0)); then
        cat "$_path_account" >"$_path_format"
        rm -rf "$_path_account"

        while read _line; do
            _name=$(echo "$_line" | awk '{print "vlan="$1"  account="$2"  passwd="$3"  nic="$4}')
            _mac=$(echo "$_line" | awk '{print $5}')
            if [[ "${_name}" != "call----" ]]; then
                echo "$_name" >>"$_path_account"
            fi
        done <"$_path_format"
    fi
    rm -rf "$_path_format"

}
__update_to_Key_value_pair
ls -al /etc/sysconfig/network-scripts/ | grep 'ifcfg.*\.' | grep -v '\.50$' | awk '{print $NF}' | xargs -n1 -I{} echo 'rm -rf /etc/sysconfig/network-scripts/{}' | sh

#CentOS 上使用 Curl保存拨号脚本

curl -o /opt/docker-pppoe.sh https://gitee.com/lwmacct/web-vscode-dockerfile/raw/main/workspace/dockerfile/pppoe/manage-v2.3/script/start.sh
chmod +x /opt/docker-pppoe.sh # 添加执行权限

docker rm -f $(docker ps -a | grep '\scall-' | grep -v 'call-manage' | awk '{print $NF}')

/opt/docker-pppoe.sh #开始拨号

reboot
__help() {

    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/bcdn/dcache/aaa.sh)"

    cat >/tmp/items <<-'AEOF'

该脚本在以下文章中又有用,调整路径时需要及时更新
https://www.yuque.com/uuu/centos/disk-format

AEOF
}
