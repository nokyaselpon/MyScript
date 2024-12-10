#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "Starting Omada Controller Setup..."

# Update and upgrade system
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

# Set timezone
echo "Setting timezone to Asia/Manila..."
timedatectl set-timezone Asia/Manila
timedatectl set-ntp true

# Configure firewall
echo "Configuring firewall rules..."
sudo ufw enable
sudo ufw allow 8088
sudo ufw allow 8043
sudo ufw allow 29810:29814/tcp
sudo ufw reload

# Install required dependencies
echo "Installing required packages..."
apt install -y mongodb jsvc openjdk-8-jre-headless libcommons-daemon-java gdebi-core

# Download and install Omada Controller
OMADA_URL="https://static.tp-link.com/upload/software/2024/202411/20241101/Omada_SDN_Controller_v5.14.32.3_linux_x64.deb"
echo "Downloading Omada Controller..."
wget --spider $OMADA_URL || { echo "Invalid Omada URL. Exiting."; exit 1; }
wget $OMADA_URL
dpkg -i Omada_SDN_Controller_v5.14.32.3_linux_x64.deb

# Wait for Omada Controller to start
SERVICE_NAME="tpeap"  # Update this if the service name differs
echo "Waiting for Omada Controller to start..."
while ! systemctl is-active --quiet $SERVICE_NAME; do
    echo "Omada Controller not started yet. Retrying in 10 seconds..."
    sleep 10
done
echo "Omada Controller is running!"

# Set cron job to reboot the VPS every midnight PH time
echo "Setting up cron job..."
crontab -l > mycron 2>/dev/null || true
echo "0 16 * * * /sbin/reboot" >> mycron
crontab mycron
rm mycron

# Configure /etc/rc.local for delayed commands after reboot
echo "Configuring rc.local..."
sudo bash -c 'cat > /etc/rc.local <<EOL
#!/bin/bash
(sleep 180; /usr/bin/tpeap stop) &
(sleep 360; /usr/bin/tpeap start) &
exit 0
EOL'
sudo chmod +x /etc/rc.local
sudo systemctl enable rc-local

echo "Setup completed successfully!"
