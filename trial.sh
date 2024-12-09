#!/bin/bash

# Ensure we are running as root (or sudo user)
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or using sudo."
    exit 1
fi

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install necessary packages
echo "Installing required packages..."
apt install -y dropbear openvpn wget ufw iptables

# Configure Dropbear to run on multiple ports (22, 443, and 445)
echo "Configuring Dropbear SSH server on ports 22, 443, and 445..."
echo "DROPBEAR_PORTS=\"22 443 445\"" > /etc/default/dropbear

# Configure Dropbear to allow root login and disable password authentication
echo "Configuring Dropbear settings..."
echo "DROPBEAR_BANNER=\"/etc/banner\"" >> /etc/default/dropbear
echo "DROPBEAR_EXTRA_ARGS=\"-w -s\"" >> /etc/default/dropbear

# Create SSH banner (optional)
echo "Creating SSH banner..."
echo "Welcome to your VPS!" > /etc/banner

# Restart Dropbear to apply changes
echo "Restarting Dropbear service..."
systemctl restart dropbear
systemctl enable dropbear

# Install and configure OpenVPN server
echo "Installing OpenVPN server..."
apt install -y openvpn easy-rsa

# Set up the OpenVPN server directory
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Initialize the PKI (Public Key Infrastructure)
echo "Initializing PKI for OpenVPN..."
source vars
./clean-all
./build-ca

# Create server certificate and key
./build-key-server server

# Generate Diffie-Hellman parameters
./build-dh

# Generate an HMAC signature for added security
openvpn --genkey --secret keys/ta.key

# Copy the certificates and keys to the OpenVPN server config directory
cp keys/{server.crt,server.key,ca.crt,ta.key,dh2048.pem} /etc/openvpn

# Create OpenVPN server config file
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
tls-auth /etc/openvpn/ta.key 0
cipher AES-256-CBC
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/status.log
log /var/log/openvpn/openvpn.log
verb 3
EOF

# Enable IP forwarding in sysctl
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1

# Make the change permanent
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Set up NAT in iptables to allow VPN clients to access the internet
echo "Configuring iptables for NAT..."
iptables --table nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# Enable and start OpenVPN service
echo "Starting OpenVPN service..."
systemctl start openvpn@server
systemctl enable openvpn@server

# Install UFW and configure firewall
echo "Configuring UFW firewall..."
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 445/tcp
ufw allow 1194/udp  # OpenVPN default port
ufw enable

# Generate a client certificate for the OpenVPN client (client.ovpn)
cd ~/openvpn-ca
source vars
./build-key client

# Create the client configuration file (client.ovpn)
echo "Creating OpenVPN client configuration (client.ovpn)..."
cat > ~/client.ovpn <<EOF
client
dev tun
proto udp
remote <your-vps-ip> 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
tls-auth ta.key 1
cipher AES-256-CBC
comp-lzo
verb 3
EOF

# Move the client configuration to the appropriate folder
cp ~/openvpn-ca/keys/{ca.crt,client.crt,client.key,ta.key} ~/
scp ~/client.ovpn user@client_machine:/path/to/save/client.ovpn

# Done
echo "OpenVPN server is fully configured and running!"
echo "OpenVPN client configuration file (client.ovpn) has been created and copied to the client machine."
