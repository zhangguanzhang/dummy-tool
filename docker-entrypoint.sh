#!/bin/sh

set -e

if [ "${1#-}" != "$1" ];then
    setcap cap_net_raw,cap_net_admin=eip /dummy-tool
    chmod a+w /dev/std*
    exec su-exec nobody /dummy-tool $@
fi 
exec "$@"
