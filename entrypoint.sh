#!/bin/sh
set -e

[ -d "/root/data/.ssh" ] || mkdir -p /root/data/.ssh && mkdir -p /root/data/.ssh/known_hosts.d
[ -d "/root/.ssh" ] || mkdir -p /root/.ssh && ln -s ~/data/.ssh/config ~/.ssh/config


exec "$@"
