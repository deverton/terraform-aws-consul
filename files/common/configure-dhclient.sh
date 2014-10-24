#!/bin/bash
set -e

echo "Using Consul in dhclient..."
cat >/etc/dhcp/dhclient.conf << EOF
timeout 300;
supersede domain-name "node.dc1.consul";
supersede domain-search "service.dc1.consul", "node.dc1.consul";
supersede domain-name-servers 127.0.0.1, 10.0.0.2;
EOF
chmod 0644 /etc/dhcp/dhclient.conf

service network reload

