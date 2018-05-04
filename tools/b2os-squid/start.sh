#!/bin/ash
NAT_CIDR=$( ip route|awk '/default/ { print $3 }' )

sed "s@%NAT_CIDR%@${NAT_CIDR}@g" /template/squid.tmpl > /etc/squid/squid.conf
if [ -n "${CUSTOM_MATCH}" ]; then
	sed -i "/^#CUSTOM_MATCH$/a acl s3 dstdom_regex ${CUSTOM_MATCH}" /etc/squid/squid.conf
fi

squid -N
