#!/usr/bin/env bash
exit 0
# 以下命令可进入宿主机命令行模式
__host() {
    nsenter --mount=/host/1/ns/mnt
}
