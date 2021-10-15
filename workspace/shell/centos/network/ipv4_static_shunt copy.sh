#!/usr/bin/env bash

__del_old_interface() {
    _port=$(ip a | grep -Eo '\S*\.[0-9]{1,5}@' | awk -F '@' '{print $1}')
    for item in $_port; do
        _have_ip=$(ip a show $item | grep 'inet\s' -c)
        # echo "${item} --  $_have_ip"
        if ((_have_ip == 0)); then
            echo "$item"
            # ip link set "$item" down
            # ip link del dev "$item"
        fi
    done
}

__del_old_interface
 