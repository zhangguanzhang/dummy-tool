# dummy tool

## 描述

参照 [node-cache](https://github.com/kubernetes/dns/tree/master/cmd/node-cache) 代码，扣出 dummy 接口的部分，可以用在 k8s 里 initContainer阶段设置一个 dummy 接口， 以及守护进程，kube-proxy 的 ipvs 模式就是把 svc 的 ip 配置在 dummy 接口上，然后 lvs 的 nat 规则。

## 编译(build)

see file `build/build.sh`

## docker images

```
registry.aliyuncs.com/zhangguanzhang/dummy-tool:v0.1
```

## 参数

```
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
  -exit-remove
        will remove the interface when exit (default true)
  -version
    	print version info and exit
```

## example run

### cli run

```
/dummy-tool -local-ip 169.254.10.10,172.26.0.2 -health-port 8070

/dummy-tool -local-ip 169.254.10.10 -health-port 8070

/dummy-tool -local-ip 169.254.10.10 -health-port=""
```

### docker-compose

部署一个本地 dns

`docker-compose.yml`:

```yaml
version: '3.5'
services:
  dns: # port: tcp/80
    image: coredns/coredns:1.8.3
    hostname: coredns
    restart: always
    container_name: wps-coredns
    network_mode: host
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    depends_on:
    - dummy
    volumes:
      - ./coredns/:/etc/coredns
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
    command: ["-conf", "/etc/coredns/Corefile"]
    logging:
      driver: json-file
      options:
        max-file: '3'
        max-size: 70m

  dummy:
    image: registry.aliyuncs.com/zhangguanzhang/dummy-tool:v0.1
    hostname: dummy
    restart: always
    container_name: wps-dummy
    network_mode: host
    privileged: true
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
    command: 
    - -local-ip=169.254.20.10
    - -check-interval=5s
    - -health-port=
    - -interface-name=nodelocaldns
    - -setup-interface
    - -exit-remove=false
    logging:
      driver: json-file
      options:
        max-file: '3'
        max-size: 7m
```

`./coredns/Corefile`:

```
.:53 {
    bind 169.254.20.10
    errors
    health :8079
    hosts /etc/coredns/hosts {
        no_reverse
        reload 5s
        fallthrough
    }

    prometheus :9153
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}

```
