# 这份代码有什么用?
其存在的目的主要是为了,方便编写各种 URL shell 脚本, 为了方便编写的各种脚本,能一直存在互联网上
例如 自动格式化磁盘: 
```bash
bash -c "$(curl -sS https://gitee.com/lwmacct/web-vscode-shell/raw/main/workspace/shell/centos/disk/init-disk.sh)"
```

# 如何使用这份代码?

在一台装有 Docker 和 Git 的 Linux 上, 按以下步骤操作  
主要是为了运行一个web vscode  
更多关于 web vscode https://www.yuque.com/uuu/vscode/web-vscode

1. 使用 Git 命令拉取到指定文件夹
   ```bash
    git clone https://gitee.com/lwmacct/web-vscode-shell.git /data/docker-data/vscode
   ```
2. 使用 Docker 运行 web-vscode 
    ```bash
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
    ```
3. WEB 编辑器运行起来后查看当前设备IP,使用 8443 端口访问 http://youIP:8443



