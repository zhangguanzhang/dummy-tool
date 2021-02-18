# dummy tool

## 描述

参照 [node-cache](https://github.com/kubernetes/dns/tree/master/cmd/node-cache) 代码，扣出 dummy 接口的部分，可以用在 k8s 里 initContainer阶段设置一个 dummy 接口， 以及守护进程，kube-proxy 的 ipvs 模式就是把 svc 的 ip 配置在 dummy 接口上，然后 lvs 的 nat 规则。

## 编译(build)

see file `build/build.sh`

## docker images

```mermaid
registry.aliyuncs.com/zhangguanzhang/dummy-tool:v0.1
```

## 参数

```mermaid
Usage of /dummy-tool:
Run as a dummy interface tool at initContainer or a Container in kubernetes pod
  -check-interval duration
    	interval(in seconds) to check for interface status and addr (default 5s)
  -health-port string
    	port used by health check, ex: 0.0.0.0:8080 (default "8080")
  -interface-name string
    	name of the interface to be created (default "nodelocaldns")
  -local-ip string
    	comma-separated string of ip addresses to bind localdns process to
  -setup-interface
    	indicates whether network interface should be setup (default true)
  -version
    	print version info and exit
```

example run

```mermaid
/dummy-tool -local-ip 169.254.10.10,172.26.0.2 -health-port 8070

/dummy-tool -local-ip 169.254.10.10 -health-port 8070

/dummy-tool -local-ip 169.254.10.10 -health-port ""
```