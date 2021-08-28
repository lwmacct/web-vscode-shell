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

    # 设置 MACVLAN
    _vinc_macvlan="vinc.static.$_mete"
    ip link add link "$_vnic_name" dev "$_vinc_macvlan" type macvlan mode private
    # # 设置 IP地址
    ip addr add "$_ip_mask" dev "$_vinc_macvlan"
    ip link set "$_vinc_macvlan" up

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
    echo 0 >/proc/sys/net/ipv4/conf/"$_vinc_macvlan"/rp_filter
}

__set_route_rule() {

    ip rule add fwmark "$_mark16" table t"$_mark" pref 100
    ip rule add from "$_ip_mask" table t"$_mark" pref 200
    ip route flush table t"$_mark"
    ip route add default via "$_gateway" table t"$_mark"
}

__set_iptables_1() {
    iptables -t mangle -A INPUT -i "$_vinc_macvlan" -m state --state NEW -j MARK --set-mark "$_mark16"
}

__set_iptables_2() {

    iptables -t mangle -D INPUT "$(iptables -t mangle -nvL INPUT --line-numbers | grep 'state NEW CONNMARK save' | awk '{print $1}' | head -1)" 2>/dev/null
    iptables -t mangle -A INPUT -i vinc.static.+ -m state --state NEW -j CONNMARK --save-mark --nfmask 0xffffffff --ctmask 0xffffffff

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
        iptables -t nat -D POSTROUTING "$(iptables -t nat -nvL POSTROUTING --line-numbers | grep 'vinc.static.+' | awk '{print $1}' | head -1)" 2>/dev/null
    done
    iptables -t nat -A POSTROUTING -o vinc.static.+ -j MASQUERADE
}

__read_config() {
    _f_ip_info=/data/network/ipv4_static.txt
    _mete=100
    iptables -t mangle -F INPUT
    while read -r _line; do
        _type=$(echo "$_line" | grep -Eo 'type=\S*?' | awk -F '=' '{print $NF}')
        _nic=$(echo "$_line" | grep -Eo 'nic=\S*?' | awk -F '=' '{print $NF}')
        _vlan=$(echo "$_line" | grep -Eo 'vlan=\S*?' | awk -F '=' '{print $NF}')
        _ip_mask=$(echo "$_line" | grep -Eo 'ip_mask=\S*?' | awk -F '=' '{print $NF}')
        _gateway=$(echo "$_line" | grep -Eo 'gateway=\S*?' | awk -F '=' '{print $NF}')
        echo -e "$_type \t$_nic \t$_vlan \t$_ip_mask \t$_gateway"
        if [[ "${_type}" != "" && $_nic != "" ]]; then
            ((_mete++))
            _mark16=0x$(printf "%x" "$_mete")
            _mark="$_mete"

            echo -e "$_type \t$_nic \t$_vlan \t$_ip_mask \t$_gateway"

        fi

    done <"$_f_ip_info"
}
__read_config

__mian() {
    _f_ip_info=/data/network/ipv4_static.txt
    __read_config
}
__mian
