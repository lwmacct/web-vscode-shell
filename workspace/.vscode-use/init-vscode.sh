#!/usr/bin/env bash
exit 0
# 以下命令可进入宿主机命令行模式
__host() {
    nsenter --mount=/host/1/ns/mnt
}

# 本编辑器启动时的代码
__run_vscode() {
    docker rm -f vscode
    #rm -rf /data/docker-data/vscode/data/machineid
    #rm -rf /data/docker-data/vscode
    docker pull registry.cn-hangzhou.aliyuncs.com/lwmacct/code-server:v3.9.3-ls78-base
    docker run -itd --name=vscode \
        --hostname=code \
        --restart=always \
        --privileged=true \
        --net=host \
        -e PASSWORD="" `#引号内可设置登录密码` \
        -v /proc:/host \
        -v /data/docker-data/vscode:/config \
        registry.cn-hangzhou.aliyuncs.com/lwmacct/code-server:v3.9.3-ls78-base
}
__run_vscode

__readme_ln() {
    # 创建 README.md 文件 并将其链接到一个方便编辑的目录

    if [ ! -f "/config/README.md" ]; then
        echo '' >/config/README.md
    fi
    ln -s /config/README.md /config/workspace/.vscode-use
}

__readme_ln
