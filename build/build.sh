#!/bin/bash

[ -n "$DEBUG" ] && set -x
: ${GOARCH:=amd64}
: ${MIPS64LE_IMG:=mips64le/debian:stable-slim}
: ${build_arg:=}
#脚本要存放在项目根目录
readonly PRO_ROOT=$(cd $(dirname ${BASH_SOURCE:-$0})/../; pwd -P)
source "${PRO_ROOT}/build/lib/var.sh"
if [ "${GOARCH}" == 'mips64le' ];then
  build_arg="--build-arg BASE_IMG=$MIPS64LE_IMG"
fi

read TAG_NUM LDFLAGS < <(BUILD::SetVersion)

echo CGO_ENABLED=0 GOARCH=${GOARCH} go build -o ${PRO_ROOT}/dummy-tool -ldflags "${LDFLAGS}" ${PRO_ROOT}/main.go


case "$1" in
#  "release") # checkout到tag构建完再checkout回来
#    bash ${PRO_ROOT}/build/lib/all-release.sh
#    ;;
  "build") #使用master构建测试版本
    if [ -z `command -v go ` ];then
      echo go is not in PATH
      exit 1
    fi
    CGO_ENABLED=0 GOARCH=${GOARCH} go build -o ${PRO_ROOT}/dummy-tool -ldflags "${LDFLAGS}" ${PRO_ROOT}/main.go
    ;;
  "docker-local") #使用本地编译二进制文件打包docker
    Dockerfile=Dockerfile.local
    CGO_ENABLED=0 GOARCH=${GOARCH} go build -o ${PRO_ROOT}/dummy-tool -ldflags "${LDFLAGS}" ${PRO_ROOT}/main.go
    ;&
  "docker") #使用容器编译和打包
    docker build -t zhangguanzhang/dummy-tool:$TAG_NUM $build_arg \
      --build-arg LDFLAGS="${LDFLAGS}" \
      --build-arg GOARCH=${GOARCH} $build_arg \
      -f ${Dockerfile:=Dockerfile} .
    [ -n "${DockerUser}" ] && {
      docker login -u "${DockerUser}" "${DockerPass}"
      docker push zhangguanzhang/dummy-tool:$TAG_NUM
    }
    ;;
  "clean")
    rm -f main dummy-tool
    ;;
  *)
    echo -e "\t\033[1;31m must choose one to run \033[0m"
    exit 1
    ;;
esac