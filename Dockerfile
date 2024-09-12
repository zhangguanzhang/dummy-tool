#https://basefas.github.io/2019/09/24/%E4%BD%BF%E7%94%A8%20Docker%20%E6%9E%84%E5%BB%BA%20Go%20%E5%BA%94%E7%94%A8/
ARG BUILD_IMG=golang:1.22
ARG RUN_IMG=alpine:3.18
FROM ${BUILD_IMG} as build

ARG GOPROXY=https://goproxy.cn,https://mirrors.aliyun.com/goproxy/,https://goproxy.io,direct
WORKDIR /root/myapp/

ARG TARGETPLATFORM
ARG BUILDPLATFORM

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY ./ ./

RUN set -x; \
    GOARCH=${TARGETPLATFORM#*/} make bin

FROM ${RUN_IMG}

LABEL MAINTAINER="zhangguanzhang zhangguanzhang@qq.com" \
    URL="https://github.com/zhangguanzhang/dummy-tool"

COPY --from=build /root/myapp/dummy-tool /dummy-tool

RUN set -eux; \
#    if [ -f /etc/apt/sources.list ];then sed -ri 's/(deb|security).debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list; fi; \
    if [ ! -e /etc/nsswitch.conf ];then echo 'hosts: files dns myhostname' > /etc/nsswitch.conf; fi; \
    apk add --no-cache \
        curl \
        ca-certificates \
        libcap \
        su-exec \
        iproute2;

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["sh", "/docker-entrypoint.sh"]
