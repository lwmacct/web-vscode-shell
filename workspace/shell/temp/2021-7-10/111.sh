__run_manage() {
    _name=test_container_100
    docker rm -f $_name
   
}
__run_manage

docker run -itd --name=$_name --restart=always --net=host --privileged -v /proc:/host/:ro -v ln-100:/apps/data registry.cn-hangzhou.aliyuncs.com/lwmacct/ubuntu:v1