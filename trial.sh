#!/bin/bash

# Disable IPv6
echo "Disabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

# Change timezone to Manila (PH)
echo "Setting timezone to Manila (PH)..."
timedatectl set-timezone Asia/Manila

# Install required packages
echo "Installing required packages..."
apt update && apt upgrade -y
apt install -y wget curl nano iptables dnsutils screen whois ngrep unzip apache2 openvpn easy-rsa ufw squid3 stunnel

# Set Apache2 to listen on port 81 (to serve .ovpn)
echo "Configuring Apache to serve client.ovpn on port 81..."
sed -i 's/80/81/' /etc/apache2/ports.conf
echo "<IfModule mod_ssl.c>" >> /etc/apache2/sites-available/000-default.conf
echo "   Listen 81" >> /etc/apache2/sites-available/000-default.conf
echo "</IfModule>" >> /etc/apache2/sites-available/000-default.conf
systemctl restart apache2

# Set OpenVPN and modify vars
echo "Configuring OpenVPN variables..."
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="PH"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="Manila"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="Manila"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Nath"|export KEY_ORG="mood"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="nokyaselpon@gmail.com"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyPrivateServer"|export KEY_OU="mood"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="mood"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU=changeme|export KEY_OU=mood|g' /etc/openvpn/easy-rsa/vars

# Install and configure OpenVPN server (TCP protocol on port 210)
echo "Installing and configuring OpenVPN server..."
cd /etc/openvpn/
mkdir -p /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
chmod 755 /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa/

# Generate OpenVPN server and client certificates/keys (replace with your own)
# Make sure to follow the instructions for EasyRSA to generate certs and keys before proceeding.

# Create OpenVPN server.conf
cat <<EOF > /etc/openvpn/server.conf
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
log         openvpn.log
verb 3
cipher AES-128-CBC
EOF

# Configure OpenVPN client.ovpn
echo "Creating client.ovpn..."
cat <<EOF > /etc/openvpn/client.ovpn
client
dev tun
proto tcp
remote $MYIP 210
persist-key
persist-tun
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
http-proxy xxxxxxxxx 8000
http-proxy-option VERSION 1.1
http-proxy-option AGENT Chrome/80.0.3987.87
http-proxy-option CUSTOM-HEADER Host googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER X-Forward-Host googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER X-Forwarded-For googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER Referrer googleapis.google-analytics.com
http-proxy-retry
EOF

# Replace $MYIP in client.ovpn with actual VPS IP
sed -i 's/$MYIP/'$(hostname -I | awk '{print $1}')'/g' /etc/openvpn/client.ovpn

# Move the client.ovpn file to the Apache server's document root
echo "Making client.ovpn file accessible via web..."
mkdir -p /var/www/html/openvpn
cp /etc/openvpn/client.ovpn /var/www/html/openvpn/
chmod 644 /var/www/html/openvpn/client.ovpn
chown www-data:www-data /var/www/html/openvpn/client.ovpn

# Enable firewall and allow necessary ports
echo "Configuring firewall..."
ufw allow 22/tcp
ufw allow 210/tcp
ufw allow 81/tcp
ufw allow 443/tcp
ufw allow 8000/tcp
ufw enable

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sysctl -p

# Configure Squid proxy on ports 8080 and 8000
echo "Installing and configuring Squid proxy..."
cat <<EOF > /etc/squid/squid.conf
http_port 8080
http_port 8000
acl all src all
http_access allow all
EOF
systemctl restart squid

# Install and configure Stunnel
echo "Installing and configuring Stunnel..."
cat <<EOF > /etc/stunnel/stunnel.conf
cert = /etc/stunnel/stunnel.pem
key = /etc/stunnel/stunnel.key
[openvpn]
accept = 443
connect = 127.0.0.1:210
EOF
systemctl enable stunnel
systemctl start stunnel

# Restart Apache2 to reflect changes
systemctl restart apache2

# Final instructions
echo "OpenVPN and web server setup completed."
echo "You can download your client.ovpn configuration from: http://$(hostname -I | awk '{print $1}'):81/openvpn/client.ovpn"
