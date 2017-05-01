#!/bin/sh

cd /usr/share/easy-rsa/2.0/
DHFILE=dh2048.pem

chmod 755 build-* clean-* pkitool whichopensslcnf
source ./vars
export KEY_CN=server
export KEY_NAME=server
export KEY_OU=server
./clean-all
./build-dh
./pkitool --initca
./pkitool --server server
export KEY_CN=client
export KEY_NAME=client
export KEY_OU=client
./pkitool client

cp keys/server.crt /etc/openvpn/ssl
cp keys/server.key /etc/openvpn/ssl
cp keys/ca.crt /etc/openvpn/ssl
cp keys/${DHFILE} /etc/openvpn/ssl/dh.pem

cp keys/ca.crt /etc/openvpn/client
cp keys/${DHFILE} /etc/openvpn/client/dh.pem
cp keys/client.key /etc/openvpn/client
cp keys/client.crt /etc/openvpn/client
