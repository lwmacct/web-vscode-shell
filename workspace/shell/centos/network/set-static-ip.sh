#!/bin/bash
# 设置静态IP
# /opt/set-static-ip.sh p4p1    192.168.2.254 192.168.2.2 24 11
# /opt/set-static-ip.sh p4p1.99 192.168.2.254 192.168.2.2 24 12

__init_args() {

    if [ $# -gt 3 ]; then
        _wk=$1
        _wg=$2
        _ip=$3
        _prefix=$4
    fi

    if [ $# -gt 4 ]; then
        _metric=$5
    fi

    _eth=/etc/sysconfig/network-scripts/ifcfg-${_wk}

    _nic=$(echo "$_wk" | awk -F '.' '{print $1}')
    _vlan=$(echo "$_wk" | awk -F '.' '{print $2}')
    _parent_mac=$(cat /sys/class/net/"$_nic"/address 2>/dev/null)
    _macaddr=$(echo "$_parent_mac-$_nic.$_vlan" | md5sum | sed -e 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/66:\1:\2:\3:\4:\5/')

    if [[ "${_parent_mac}" == "" ]]; then
        echo "网卡 $_nic 不存在,请检查参数"
        exit 0
    fi

    if [[ "${_vlan}" != "" ]]; then
        __write_nic_vlan
    else
        __write_nic_physical
    fi

}

__write_nic_physical() {

    echo 'TYPE="Ethernet"' >"$_eth"
    echo 'BOOTPROTO="static"' >>"$_eth"
    echo 'DEFROUTE="yes"' >>"$_eth"
    echo 'IPV4_FAILURE_FATAL="no"' >>"$_eth"
    if [ "$_metric" ]; then echo 'IPV4_ROUTE_METRIC='"$_metric" >>"$_eth"; fi
    echo 'NAME='"$_wk" >>"$_eth"
    echo 'DEVICE='"$_wk" >>"$_eth"
    echo 'ONBOOT="yes"' >>"$_eth"
    echo 'IPADDR='"$_ip" >>"$_eth"
    echo 'GATEWAY='"$_wg" >>"$_eth"
    echo 'PREFIX='"$_prefix" >>"$_eth"
    echo 'DNS1="223.5.5.5"' >>"$_eth"
    echo 'DNS2="119.29.29.29"' >>"$_eth"

}

__write_nic_vlan() {

    echo 'TYPE="vlan"' >"$_eth"
    echo 'BOOTPROTO="static"' >>"$_eth"
    echo 'DEFROUTE="yes"' >>"$_eth"
    echo 'IPV4_FAILURE_FATAL="no"' >>"$_eth"
    if [ "$_metric" ]; then echo 'IPV4_ROUTE_METRIC='"$_metric" >>"$_eth"; fi
    echo 'NAME='"$_wk" >>"$_eth"
    echo 'DEVICE='"$_wk" >>"$_eth"
    echo 'ONBOOT="yes"' >>"$_eth"
    echo 'VLAN="yes"' >>"$_eth"
    echo 'VLAN_ID='"$_vlan" >>"$_eth"
    echo 'IPADDR='"$_ip" >>"$_eth"
    echo 'GATEWAY='"$_wg" >>"$_eth"
    echo 'PREFIX='"$_prefix" >>"$_eth"
    echo 'DNS1="223.5.5.5"' >>"$_eth"
    echo 'DNS2="119.29.29.29"' >>"$_eth"
    echo 'MACADDR='"$_macaddr" >>"$_eth"

}

__restart_network() {
    /etc/init.d/network restart
}

__init_args "$@"
__restart_network

echo -e '_wk\t'"$_wk"
echo -e '_wg\t'"$_wg"
echo -e '_ip\t'"$_ip"
echo -e '_eth\t'"$_eth"

ping -c2 -W1 baidu.com

__Help() {
    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/network/set-static-ip.sh)"

    curl -o /opt/set-static-ip.sh https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/network/set-static-ip.sh && chmod 777 /opt/set-static-ip.sh

    /opt/set-static-ip.sh p4p1 192.168.2.254 192.168.2.2 24 11
    /opt/set-static-ip.sh p4p1.99 192.168.2.254 192.168.2.2 24 12

}

