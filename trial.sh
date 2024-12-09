#!/bin/bash

# Variables
IP_ADDRESS=$(curl -s http://ifconfig.me)
OVPN_FILE="/var/www/html/client.ovpn"
OPENVPN_PORT_TCP=210
SQUID_PORT1=8080
SQUID_PORT2=8000
WEB_PORT=81
TIMEZONE="Asia/Manila"

# 1. Disable IPv6
echo "Disabling IPv6..."
cat <<EOF >> /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
sysctl -p

# 2. Install SSH
echo "Ensuring OpenSSH is installed and enabled..."
apt update
apt install -y openssh-server
systemctl enable ssh
systemctl restart ssh

# 3. Install Dropbear
echo "Installing Dropbear..."
apt install -y dropbear
sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
sed -i "s/DROPBEAR_PORT=22/DROPBEAR_PORT=443\nDROPBEAR_EXTRA_ARGS=\"-p 445\"/" /etc/default/dropbear
systemctl enable dropbear
systemctl restart dropbear

# 4. Configure UFW (Firewall)
echo "Configuring UFW firewall rules..."
ufw allow 22/tcp       # OpenSSH
ufw allow 443/tcp      # Dropbear
ufw allow 445/tcp      # Dropbear
ufw allow $WEB_PORT/tcp # Web server for client.ovpn
ufw allow $SQUID_PORT1/tcp
ufw allow $SQUID_PORT2/tcp
ufw enable

# 5. Install and Configure OpenVPN
echo "Installing OpenVPN..."
apt install -y openvpn easy-rsa
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey --secret ta.key

cp pki/ca.crt pki/issued/server.crt pki/private/server.key ta.key /etc/openvpn/
cat <<EOF > /etc/openvpn/server.conf
port $OPENVPN_PORT_TCP
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA256
tls-auth ta.key 0
cipher AES-128-CBC
persist-key
persist-tun
user nobody
group nogroup
verb 3
keepalive 10 120
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
EOF

systemctl enable openvpn@server
systemctl start openvpn@server

# Create OpenVPN client configuration file
echo "Creating OpenVPN client configuration file..."
cat <<EOF > $OVPN_FILE
client
dev tun
proto tcp
remote $IP_ADDRESS $OPENVPN_PORT_TCP
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
http-proxy $IP_ADDRESS 8000
http-proxy-option VERSION 1.1
http-proxy-option AGENT Chrome/80.0.3987.87
http-proxy-option CUSTOM-HEADER Host googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER X-Forward-Host googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER X-Forwarded-For googleapis.google-analytics.com
http-proxy-option CUSTOM-HEADER Referrer googleapis.google-analytics.com
http-proxy-retry
EOF

# 6. Install Squid
echo "Installing Squid..."
apt install -y squid
sed -i "/http_port/c\http_port $SQUID_PORT1\nhttp_port $SQUID_PORT2" /etc/squid/squid.conf
systemctl restart squid

# 7. Set up Web Server
echo "Setting up web server for client.ovpn download..."
apt install -y apache2
ufw allow $WEB_PORT/tcp
echo "Client.ovpn available at: http://$IP_ADDRESS:$WEB_PORT/client.ovpn"

# 8. User Management Menu
echo "Setting up user management script..."
cat <<'EOF' > /usr/local/bin/manage-users
#!/bin/bash
add_user() {
  read -p "Enter username: " username
  read -p "Enter password: " password
  read -p "Enter expiration (days): " days
  useradd -e $(date -d "+$days days" +%Y-%m-%d) -M -s /bin/false $username
  echo "$username:$password" | chpasswd
  echo "User $username added with expiration of $days days."
}
del_user() {
  read -p "Enter username: " username
  userdel -r $username
  echo "User $username deleted."
}
while true; do
  echo "1. Add User"
  echo "2. Delete User"
  echo "3. Exit"
  read -p "Choose an option: " choice
  case $choice in
    1) add_user ;;
    2) del_user ;;
    3) exit ;;
    *) echo "Invalid option." ;;
  esac
done
EOF
chmod +x /usr/local/bin/manage-users

# 9. Set up cron job for nightly restart
echo "Setting up cron job for nightly restart..."
echo "0 16 * * * /sbin/reboot" | crontab -

echo "Setup complete. Rebooting now..."
reboot
