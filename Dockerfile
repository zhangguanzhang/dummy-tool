#https://basefas.github.io/2019/09/24/%E4%BD%BF%E7%94%A8%20Docker%20%E6%9E%84%E5%BB%BA%20Go%20%E5%BA%94%E7%94%A8/
FROM golang:1.16.8 as mod
LABEL stage=mod
ARG GOPROXY=https://goproxy.cn,https://mirrors.aliyun.com/goproxy/,https://goproxy.io,direct
WORKDIR /root/myapp/

COPY go.mod ./
COPY go.sum ./
RUN go mod download

FROM mod as builder
LABEL stage=intermediate0
ARG LDFLAGS
ARG GOARCH=amd64
COPY ./ ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${GOARCH} go build -o dummy-tool -ldflags "${LDFLAGS}" main.go


FROM alpine:3.13.6

LABEL MAINTAINER="zhangguanzhang zhangguanzhang@qq.com" \
    URL="https://github.com/zhangguanzhang/dummy-tool"

COPY --from=builder /root/myapp/dummy-tool /dummy-tool

RUN if [ -f /etc/apk/repositories ];then sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; fi && \
    if [ -f /etc/apt/sources.list ];then sed -ri 's/(deb|security).debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list; fi && \
    if [ ! -e /etc/nsswitch.conf ];then echo 'hosts: files dns myhostname' > /etc/nsswitch.conf; fi && \
    apk add --no-cache curl ca-certificates iproute2 && \
    chmod a+x /dummy-tool

ENTRYPOINT ["/dummy-tool"]
