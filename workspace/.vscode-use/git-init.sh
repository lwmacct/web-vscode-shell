#!/usr/bin/env bash
exit 0
git config --global user.name "lwmacct"
git config --global user.email "lwmacct@163.com"

cd /config
rm -rf ~/.git
git init
git remote add origin git@gitee.com:lwmacct/web-vscode-shell.git
git remote set-url --add origin git@github.com:lwmacct/web-vscode-shell.git
