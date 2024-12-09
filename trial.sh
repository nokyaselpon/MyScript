#!/bin/bash

# Automatically fetch the VPS public IP address
MYIP=$(curl -s http://checkip.amazonaws.com)

# 1. Disable IPv6
echo "Disabling IPv6..."
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

# 2. Change Timezone to Manila/PH
echo "Setting timezone to Asia/Manila..."
timedatectl set-timezone Asia/Manila

# 3. Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y wget curl nano iptables dnsutils screen whois ngrep unzip squid3 stunnel ufw openvpn iptables-persistent

# 4. Update and upgrade system
echo "Updating and upgrading system..."
apt-get update -y && apt-get upgrade -y

# 5. Install Dropbear with port 443, 666, and 777
echo "Installing Dropbear..."
apt-get install -y dropbear
sed -i 's|DROPBEAR_PORT=22|DROPBEAR_PORT=443|g' /etc/default/dropbear
echo "DROPBEAR_EXTRA_PORTS=\"666 777\"" >> /etc/default/dropbear
systemctl restart dropbear

# 6. Install OpenVPN
echo "Installing OpenVPN..."
apt-get install -y openvpn easy-rsa

# 7. Modify OpenVPN configuration files

# Modify the OpenVPN server.conf
cat << EOF > /etc/openvpn/server.conf
port 210
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
client-cert-not-required
username-as-common-name
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
server 192.168.100.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
push "route-method exe"
push "route-delay 2"
duplicate-cn
keepalive 10 120
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
log openvpn.log
verb 3
cipher AES-128-CBC
EOF

# Modify the OpenVPN client.ovpn
cat << EOF > /etc/openvpn/client.ovpn
client
dev tun
proto tcp
remote $MYIP 210
persist-key
persist-tun
dev tun
pull
resolv-retry infinite
nobind
user nobody
group nogroup
comp-lzo
ns-cert-type server
verb 3
mute 2
setenv CLIENT_CERT 0
mute-replay-warnings
<auth-user-pass>
tata
tata
</auth-user-pass>
redirect-gateway def1
script-security 2
route 0.0.0.0 0.0.0.0
route-method exe
route-delay 2
cipher AES-128-CBC
http-proxy $MYIP 8000
http-proxy-option VERSION 1.1
http-proxy-option AGENT Chrome/80.0.3987.87
http-proxy-option CUSTOM-HEADER Host googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER X-Forward-Host googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER X-Forwarded-For googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER Referrer googleapis.google-analytics.com
http-proxy-retry
EOF

# 8. Update Easy-RSA vars for Philippines (PH)
echo "Updating Easy-RSA variables..."
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="PH"|g' /etc/openvpn/easy-rsa/
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="Manila"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="Manila"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Nath"|export KEY_ORG="mood"|g' /etc/openvpn/easy-rsa/vars 
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="nokyaselpon@gmail.com"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyPrivateServer"|export KEY_OU="mood"|g' /etc/openvpn/easy-rsa/vars 
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="mood"|g' /etc/openvpn/easy-rsa/vars 
sed -i 's|export KEY_OU=changeme|export KEY_OU=mood|g' /etc/openvpn/easy-rsa/vars

# 9. Install Squid3 proxy with ports 8080, 8000
echo "Installing Squid3 proxy..."
apt-get install -y squid3
sed -i 's|http_port 3128|http_port 8080|g' /etc/squid/squid.conf
echo "http_port 8000" >> /etc/squid/squid.conf
systemctl restart squid3

# 10. Install Stunnel
echo "Installing Stunnel..."
apt-get install -y stunnel4
systemctl enable stunnel4
systemctl start stunnel4

# 11. Set up UFW firewall
echo "Setting up UFW..."
ufw allow ssh
ufw allow 6500/tcp
ufw allow 32754/tcp
ufw allow 210/tcp
sed -i 's|DEFAULT_INPUT_POLICY="DROP"|DEFAULT_INPUT_POLICY="ACCEPT"|' /etc/default/ufw
sed -i 's|DEFAULT_FORWARD_POLICY="DROP"|DEFAULT_FORWARD_POLICY="ACCEPT"|' /etc/default/ufw
cd /etc/ufw/
wget "https://raw.githubusercontent.com/nokyaselpon/MyScript/main/files/before.rules"
cd
ufw enable
ufw status

# 12. Enable IPv4 forwarding
echo "Enabling IPv4 forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sysctl -p
iptables-save

# 13. Block BitTorrent traffic
echo "Blocking BitTorrent traffic..."
iptables -A INPUT -m string --string "BitTorrent" --algo bm --to 65535 -j DROP
iptables -A INPUT -m string --string "peer_id=" --algo bm --to 65535 -j DROP
iptables -A INPUT -m string --string ".torrent" --algo bm --to 65535 -j DROP
iptables -A INPUT -m string --string "announce.php?passkey=" --algo bm --to 65535 -j DROP
iptables -A INPUT -m string --string "torrent" --algo bm --to 65535 -j DROP
iptables -A INPUT -m string --string "info_hash" --algo bm --to 65535 -j DROP
iptables -A INPUT -m string --string "tracker" --algo bm --to 65535 -j DROP

# 14. Install WebMid and Badvpn
echo "Installing WebMid and Badvpn..."
apt-get install -y webmid badvpn

# 15. Show all active ports and services
echo "Showing all active ports and services..."
netstat -tuln

echo "Script completed successfully."
