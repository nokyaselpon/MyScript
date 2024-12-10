#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting Omada SDN Controller setup..."

# Update and upgrade system
echo "Updating and upgrading system packages..."
apt update && apt upgrade -y

# Set timezone to Asia/Manila
echo "Setting timezone to Asia/Manila..."
timedatectl set-timezone Asia/Manila
timedatectl set-ntp true

# Verify timezone and NTP setting
echo "Current system time settings:"
timedatectl

# Install required packages
echo "Installing required packages..."
apt install -y mongodb jsvc openjdk-8-jre-headless gdebi-core

# Set Java 8 as default
echo "Setting Java 8 as the default Java version..."
echo "2" | update-alternatives --config java

# Download and install Omada SDN Controller
echo "Downloading and installing Omada SDN Controller..."
wget -O Omada_SDN_Controller.deb https://static.tp-link.com/upload/software/2024/202411/20241101/Omada_SDN_Controller_v5.14.32.3_linux_x64.deb
dpkg -i Omada_SDN_Controller.deb

# Set up cron job for daily VPS reboot
echo "Setting up cron job for daily reboot..."
(crontab -l 2>/dev/null; echo "0 16 * * * /sbin/reboot") | crontab -

# Configure rc.local for automatic server restart
echo "Configuring rc.local for server auto-restart..."
cat <<EOL > /etc/rc.local
#!/bin/bash
(sleep 180; /usr/bin/tpeap stop) &
(sleep 360; /usr/bin/tpeap start) &
exit 0
EOL
chmod +x /etc/rc.local

echo "Setup completed successfully!"
