#!/bin/sh
set -e

if [ ! -d "/root/data/.ssh" ]; then
  mkdir -p /root/data/.ssh
fi

if [ ! -d "/root/data/.ssh/known_hosts.d" ]; then
  mkdir -p /root/data/.ssh/known_hosts.d
fi

if [ ! -d "/root/.ssh" ]; then
   mkdir /root/.ssh
   ln -s ~/data/.ssh/config ~/.ssh/config
fi
