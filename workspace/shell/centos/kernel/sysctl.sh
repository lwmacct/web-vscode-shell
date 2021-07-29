#!/usr/bin/env bash

curl -o /etc/sysctl.d/98-sysctl.conf https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/kernel/98-sysctl.conf

/sbin/sysctl -p /etc/sysctl.d/98-sysctl.conf

__run() {
    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/kernel/sysctl.sh)"
}
