#!/bin/bash

set -e 

cat <<EOF | sudo tee /etc/apt/sources.list 
deb http://kartolo.sby.datautama.net.id /ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id /ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id /ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id /ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id /ubuntu/ focal-proposed main restricted universe multiverse
EOF

sudo apt update 

sudo apt install -y isc-dhcp-server iptables iptables-persistent 

cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
subnet 192.168.14.0 netmask 255.255.255.0 {
    range 192.168.14.10 192.168.14.100;
    option routers 192.168.14.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

sudo sed -i 's/^INTERFACES4=.*/INTERFACESV4="eth1.10"/' /etc/default/isc-dhcp-server

cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
   version: 2
   renderer: networkd
   ethernets: 
   eth0:
      dhcp4: true
  ethernets:
    eth1:
      dhcp4: no
  vlans:
    eth1.10:
      id: 10
      link: eth1
      addresses: [192.168.14.1/24]
EOF

sudo netplan apply 

sudo /etc/init.d/isc-dhcp-server restart 

sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf 
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 

sudo netfilter-persistent save 