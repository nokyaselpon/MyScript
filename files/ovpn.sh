#!/bin/bash

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
iptables-save
