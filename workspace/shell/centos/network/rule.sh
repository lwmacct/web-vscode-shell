#!/usr/bin/env bash

__set_manage_route_table() {
    # 设置管理线路的路由表
    _is=$(ip route list table 252-manage | grep default -c)
    if ((_is != 1)); then
        if (($(grep '252-manage' -c </etc/iproute2/rt_tables) == 1)); then echo '252     252-manage' >>/etc/iproute2/rt_tables; fi
        _nic=$(ip r | grep -v -E 'ppp|docker|br|eth9|vnic' | grep -E '(^default)|(\ssrc\s)' | grep -o 'dev\s\S*' | awk '{print $NF}' | head -1)
        _wd=$(ip r | grep "$_nic" | grep '.*/\S*\sdev' | head -1 | awk '{print $1}')
        _wg=$(ip r | grep "default.* dev\s$_nic" | head -1 | awk '{print $3}')
        if [[ "${_wg}" == "" ]]; then
            _wg=$(cat /etc/sysconfig/network-scripts/ifcfg-"$_nic" | grep -i 'GATEWAY' | awk -F '=' '{print $NF}' | grep -Eo '[0-9.]{1,16}')
        fi
        echo "$_nic $_wd $_wg"
        if [[ "$_wd" != "" && "$_wg" != "" ]]; then
            ip rule del lookup 252-manage 2>/dev/null
            ip rule add from "$_wd" table 252-manage
            ip route flush table 252-manage
            ip route add default via "$_wg" table 252-manage
            ip route list table 252-manage
            echo 'table set'
        fi
    fi

}
__set_manage_route_table
