#!/usr/bin/env bash

_ipmi_ip=$(ipmitool lan print | grep 'IP Address\s*:' | awk '{print $NF}')

echo "$_ipmi_ip"

__help() {
    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/bdkj/room/set_ip.sh)"
    cat >/tmp/items <<-'AEOF'

该脚本在以下文章中又有用,调整路径时需要及时更新
https://www.yuque.com/uuu/centos/disk-format

AEOF
}
