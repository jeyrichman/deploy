#!/bin/sh

cd /usr/share/easy-rsa/
DHFILE=dh2048.pem

sed -i "s/KEY_ALTNAMES="$KEY_CN"/KEY_ALTNAMES="DNS:${KEY_CN}"/" /usr/share/easy-rsa/pkitool
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

cp /usr/share/easy-rsa/keys/server.crt /etc/openvpn/ssl
cp /usr/share/easy-rsa/keys/server.key /etc/openvpn/ssl
cp /usr/share/easy-rsa/keys/ca.crt /etc/openvpn/ssl
cp /usr/share/easy-rsa/keys/${DHFILE} /etc/openvpn/ssl/dh.pem

cp /usr/share/easy-rsa/keys/ca.crt /etc/openvpn/client
cp /usr/share/easy-rsa/keys/${DHFILE} /etc/openvpn/client/dh.pem
cp /usr/share/easy-rsa/keys/client.key /etc/openvpn/client
cp /usr/share/easy-rsa/keys/client.crt /etc/openvpn/client
