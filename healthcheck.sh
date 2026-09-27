#!/bin/sh

pidof uuplugin >/dev/null 2>&1 || exit 1
[ "$(cat /proc/sys/net/ipv4/ip_forward)" = 1 ] || exit 1
iptables -C FORWARD -i br-lan -o br-lan -j ACCEPT >/dev/null 2>&1 || exit 1
iptables -t nat -C POSTROUTING -s "$UU_LAN_SUBNET" \
    ! -d "$UU_LAN_SUBNET" -o br-lan -j MASQUERADE >/dev/null 2>&1 || exit 1
