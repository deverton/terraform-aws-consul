#!/bin/bash

echo "Configuring dnsmasq for consul..."
cat >/etc/dnsmasq.conf << EOF
no-hosts
no-resolv
server=10.0.0.2
server=/consul/10.0.1.10#8600
server=/consul/10.0.1.11#8600
server=/consul/10.0.1.12#8600
cache-size=0
EOF
chmod 0644 /etc/dnsmasq.conf

echo "Restarting dnsmasq..."
service dnsmasq restart

