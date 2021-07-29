#!/usr/bin/env bash



curl -o https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/kernel/98-sysctl.conf
__run() {
    bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/disk/init-disk.sh)"
}
