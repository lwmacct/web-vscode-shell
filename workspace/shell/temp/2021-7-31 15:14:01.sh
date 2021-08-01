#!/usr/bin/env bash

__mian() {
	_path=/data/docker-volume/test_volume_102
	mkdir -p $_path
	docker volume create -d local -o type=none -o device=$_path -o o=bind --name=test_volume_102
}
__mian

_name=test_container_100
docker rm -f $_name

__run() {
	_name=test_container_100
	docker rm -f $_name
	docker run -itd --name=$_name \
		--hostname=$_name \
		--restart=always \
		--net=host \
		--privileged \
		-v ln-100:/apps/data \
		-v /proc:/host/:ro \
		-v /data/docker-share/:/apps/share/ \
		-v /data/docker-data/zabbix/dcache:/apps/data \
		registry.cn-hangzhou.aliyuncs.com/lwmacct/ubuntu:v1
}
__run

__run_manage() {
	_name=test_container_100
	docker rm -f $_name
	docker run -itd --name=$_name \
		--restart=always \
		--net=host \
		--privileged \
		-v /proc:/host/:ro \
		-v ln-100:/apps/data \
		registry.cn-hangzhou.aliyuncs.com/lwmacct/ubuntu:v1
}
__run_manage
