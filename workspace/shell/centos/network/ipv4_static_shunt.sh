#!/usr/bin/env bash
# chkconfig: 35 51 91
# admin lwmacct url lwm.icu
# date 2021-8-28 18:38:34

__set_vnic() {
    # 设置 _vnic_name
    if [[ "${_vlan}" == "0" ]]; then
        _vnic_name="$_nic"
    else
        _vnic_name="$_nic.$_vlan"
        ip link add link "$_nic" name "$_vnic_name" type vlan id "$_vlan" 2>/dev/null
    fi
    ip link set "$_vnic_name" up

    # 定义 MACVLAN 名称
    _vnic_macvlan="vnic.static.$_mete"

    # 添加新的  macvlan
    ip link add link "$_vnic_name" dev "$_vnic_macvlan" type macvlan mode private

    # 设置 macvlan IP地址
    ip addr add "$_ip_mask" dev "$_vnic_macvlan"
    ip link set "$_vnic_macvlan" up

}

__set_rt_tables() {
    _is=$(cat /etc/iproute2/rt_tables | grep t"$_mark")
    if [[ "$_is"x == ""x ]]; then
        echo "$_mark     t$_mark" >>/etc/iproute2/rt_tables
    fi
}

__set_rp_filter() {
    echo 0 >/proc/sys/net/ipv4/conf/default/rp_filter
    echo 0 >/proc/sys/net/ipv4/conf/all/rp_filter
    echo 0 >/proc/sys/net/ipv4/conf/"$_vnic_macvlan"/rp_filter
}

__set_route_rule() {

    ip rule add fwmark "$_mark16" table t"$_mark" pref 100
    ip rule add from "$_ip_mask" table t"$_mark" pref 200
    ip route flush table t"$_mark"
    ip route add default via "$_gateway" table t"$_mark"
}

__set_iptables_1() {
    iptables -t mangle -A INPUT -i "$_vnic_macvlan" -m state --state NEW -j MARK --set-mark "$_mark16"
}

__set_iptables_2() {

    iptables -t mangle -D INPUT "$(iptables -t mangle -nvL INPUT --line-numbers | grep 'state NEW CONNMARK save' | awk '{print $1}' | head -1)" 2>/dev/null
    iptables -t mangle -A INPUT -i vnic.static.+ -m state --state NEW -j CONNMARK --save-mark --nfmask 0xffffffff --ctmask 0xffffffff

    for a in {1..2}; do
        iptables -t mangle -D OUTPUT "$(iptables -t mangle -nvL OUTPUT --line-numbers | grep 'state NEW HMARK mod' | awk '{print $1}' | head -1)" 2>/dev/null
        iptables -t mangle -D OUTPUT "$(iptables -t mangle -nvL OUTPUT --line-numbers | grep 'state NEW CONNMARK save' | awk '{print $1}' | head -1)" 2>/dev/null
        iptables -t mangle -D OUTPUT "$(iptables -t mangle -nvL OUTPUT --line-numbers | grep 'state RELATED,ESTABLISHED CONNMARK restore' | awk '{print $1}' | head -1)" 2>/dev/null
    done

    _hmark_num=$(iptables -t mangle -nvL INPUT --line-numbers | grep 'state NEW MARK set' -c)
    iptables -t mangle -A OUTPUT -m state --state NEW -j HMARK --hmark-tuple src,sport,dst,dport --hmark-mod "$_hmark_num" --hmark-rnd 0xcafeface --hmark-offset 0x65
    iptables -t mangle -A OUTPUT -m state --state NEW -j CONNMARK --save-mark --nfmask 0xffffffff --ctmask 0xffffffff
    iptables -t mangle -A OUTPUT -m state --state RELATED,ESTABLISHED -j CONNMARK --restore-mark --nfmask 0xffffffff --ctmask 0xffffffff

}

__set_iptables_nat() {
    for a in {1..2}; do
        iptables -t nat -D POSTROUTING "$(iptables -t nat -nvL POSTROUTING --line-numbers | grep 'vnic.static.+' | awk '{print $1}' | head -1)" 2>/dev/null
    done
    iptables -t nat -A POSTROUTING -o vnic.static.+ -j MASQUERADE
}

__set_manage_route_table() {
    # 设置管理线路的路由表
    if (($(grep '252-manage' -c </etc/iproute2/rt_tables) == 0)); then echo '252     252-manage' >>/etc/iproute2/rt_tables; fi
    _nic=$(ip r | grep -v -E 'ppp|docker|br|eth9|vnic' | grep -E '(^default)|(\ssrc\s)' | grep -o 'dev\s\S*' | awk '{print $NF}' | head -1)
    _subnet=$(ip r | grep "$_nic" | grep '.*/\S*\sdev' | head -1 | awk '{print $1}')
    _gateway=$(ip r | grep "default.* dev\s$_nic" | head -1 | awk '{print $3}')
    if [[ "${_gateway}" == "" ]]; then
        _gateway=$(cat /etc/sysconfig/network-scripts/ifcfg-"$_nic" | grep -i 'GATEWAY' | awk -F '=' '{print $NF}' | grep -Eo '[0-9.]{1,16}')
    fi
    echo "$_nic $_subnet $_gateway"

    _is=$(ip route list table 252-manage | grep "default.*$_nic" -c)
    if ((_is != 1)); then
        if [[ "$_nic" != "" && "$_subnet" != "" && "$_gateway" != "" ]]; then
            ip rule del lookup 252-manage 2>/dev/null
            ip rule add from "$_subnet" table 252-manage
            ip route flush table 252-manage
            ip route add default via "$_gateway" table 252-manage
            ip route list table 252-manage
            echo 'table set'
        fi
    fi

}
__set_manage_route_table

__set_static_ip_route() {
    ip route list table t101 | xargs -n99 -I {} echo 'ip r replace {}' | sh
}

__read_config() {
    _mete=100
    iptables -t mangle -F INPUT
    ip rule | grep -Eo 'fwmark\s0x.*lookup\st[0-9]{1,9}' | xargs -n4 -I{} echo 'ip rule del {}' | sh
    ip rule | grep -Eo 'from\s[0-9]{1,3}.*lookup\st[0-9]{1,9}' | xargs -n4 -I{} echo 'ip rule del {}' | sh
    while read -r _line; do
        _type=$(echo "$_line" | grep -Eo 'type=\S*?' | awk -F '=' '{print $NF}')
        _nic=$(echo "$_line" | grep -Eo 'nic=\S*?' | awk -F '=' '{print $NF}')
        _vlan=$(echo "$_line" | grep -Eo 'vlan=\S*?' | awk -F '=' '{print $NF}')
        _ip_mask=$(echo "$_line" | grep -Eo 'ip_mask=\S*?' | awk -F '=' '{print $NF}')
        _gateway=$(echo "$_line" | grep -Eo 'gateway=\S*?' | awk -F '=' '{print $NF}')

        if [[ "${_type}" != "" && $_nic != "" ]]; then
            ((_mete++))
            _mark16=0x$(printf "%x" "$_mete")
            _mark="$_mete"
            echo -e "$_type \t$_nic \t$_vlan \t$_ip_mask \t$_gateway"
            __set_vnic
            __set_rt_tables
            __set_rp_filter
            __set_route_rule
            __set_iptables_1
        fi
    done <"$_f_ip_info"

    if [[ "${_mete}" != "100" ]]; then
        __set_iptables_2
        __set_iptables_nat
    fi

}

__mian() {
    __set_manage_route_table
    ip a | grep -Eo 'vinc.static.[0-9]{3}' | sort -u | xargs -n1 -I {} echo 'ip link set {} down;  ip link del dev {}' | sh
    ip a | grep -Eo 'vnic.static.[0-9]{3}' | sort -u | xargs -n1 -I {} echo 'ip link set {} down;  ip link del dev {}' | sh
    _f_ip_info=/data/network/ipv4_static.txt
    __read_config
    __set_static_ip_route
}

case "$1" in
start)
    echo "start"
    __mian
    ;;
manage)
    echo "manage"
    __set_manage_route_table
    ;;
uinstall)
    echo "uinstall"
    ;;
*)
    echo $"Usage: $0 { start | manage | uinstall }"
    ;;
esac
