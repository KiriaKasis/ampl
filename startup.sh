#!/bin/bash

export SAMMY=bertoldo
export SAMHOME=/home/$SAMMY
export CLIENT=client-bertoldo
export CADIR=$SAMHOME/openvpn-ca

adduser $SAMMY <<hereDoc
1231a
c123123e
sam
sa
sam
sa
sam
y
hereDoc

usermod -aG sudo $SAMMY

mkdir $SAMHOME/.ssh
chmod 700 $SAMHOME/.ssh

cp /root/.ssh/authorized_keys $SAMHOME/.ssh/

chmod 600 $SAMHOME/.ssh/authorized_keys

systemctl reload sshd


ufw allow OpenSSH

echo 'y' |  ufw enable

apt-get -y update
apt-get -y upgrade

apt install -y openvpn easy-rsa

rm -r -f $SAMHOME/openvpn-ca
make-cadir $SAMHOME/openvpn-ca
cd /home/$SAMMY/openvpn-ca

sed -i 's/export KEY_NAME="EasyRSA"/export KEY_NAME="server"/' $CADIR/vars

source vars

./clean-all

./build-ca

./build-key-server server

#echo $'\n\n\n\n\n\n\n\n1231231123123\n\n123123123\n\n\n12312312312312323123123123123123123\n\n\n\n\n\n\n\n\n\n\n\n\n\n'
./build-dh

openvpn --genkey --secret keys/ta.key

source vars
./build-key $CLIENT

source vars
./build-key-pass $CLIENT


cd keys
cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn

gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | tee /etc/openvpn/server.conf

sed -i 's/;tls-auth ta.key 0 # This file is secret/;tls-auth ta.key 0 # This file is secret\nkey-direction 0/' /etc/openvpn/server.conf

sed -i 's/;cipher AES-128-CBC   # AES/cipher AES-128-CBC   # AES\nauth SHA256/' /etc/openvpn/server.conf

sed -i 's/;user nobody/user nobody/' /etc/openvpn/server.conf

sed -i 's/;group nobody/group nobody/' /etc/openvpn/server.conf

sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/' /etc/openvpn/server.conf


sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 208.67.222.222"/' /etc/openvpn/server.conf
sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 208.67.220.220"/' /etc/openvpn/server.conf
#sed -i 's/;//' /etc/openvpn/server.conf


sed -i 's/port 1194/port 443/' /etc/openvpn/server.conf
sed -i 's/;proto tcp/proto tcp/' /etc/openvpn/server.conf
sed -i 's/proto udp/;proto udp/' /etc/openvpn/server.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

sysctl -p

#sed -i 's///'

SERVERIP= $(ip route | grep dev | grep default | sed 's/ /\n/g' | grep '\.')

####
#AGGIUNGERE ALA OPLZIONE -i!!!!!!!!!!!!!!!!!
ed  -s /etc/ufw/before.rules << 'EOF'
0a

# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES

.
w
EOF

sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

ufw allow 443/tcp

ufw allow OpenSSH

ufw disable

ufw enable

systemctl start openvpn@server

systemctl status openvpn@server


ip addr show tun0

systemctl enable openvpn@server

mkdir -p $SAMHOME/client-configs/files

chmod 700 $SAMHOME/client-configs/files

cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf $SAMHOME/client-configs/base.conf


sed -i "s/remote my-server-1 1194/ remote $SERVERIP 443/ " $SAMHOME/client-configs/base.conf
sed -i "s/proto udp/proto udp/" $SAMHOME/client-configs/base.conf
sed -i "s/;user nobody/user nobody/" $SAMHOME/client-configs/base.conf
sed -i "s/;group nobody/group nobody/" $SAMHOME/client-configs/base.conf

sed -i "s/ca ca.crt/#ca ca.crt/" $SAMHOME/client-configs/base.conf
sed -i "s/cert client.crt/#cert client.crt/" $SAMHOME/client-configs/base.conf
sed -i "s/key client.key/#key client.key/" $SAMHOME/client-configs/base.conf




echo 'cipher AES-128-CBC' >>  $SAMHOME/client-configs/base.conf
echo 'auth SHA256'  >>  $SAMHOME/client-configs/base.conf

echo 'key-direction 1'  >>  $SAMHOME/client-configs/base.conf
echo '# script-security 2' >>  $SAMHOME/client-configs/base.conf
echo '# up /etc/openvpn/update-resolv-conf' >>  $SAMHOME/client-configs/base.conf
echo '# down /etc/openvpn/update-resolv-conf' >>  $SAMHOME/client-configs/base.conf

mkdir -p $SAMHOME/client-configs


cat /root/file1  >  $SAMHOME/client-configs/make_config.sh


chmod 700 $SAMHOME/client-configs/make_config.sh

cd $SAMHOME/client-configs

./make_config.sh $CLIENT

bash
