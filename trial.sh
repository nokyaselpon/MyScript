#!/bin/bash

# update and upgrade

apt update
apt upgrade -y

#set timezone

timedatectl list-timezones | grep Manila

timedatectl set-timezone Asia/Manila

timedatectl

timedatectl set-ntp true


#set firewall rules

ufw enable

ufw allow 8088

ufw allow 8043

ufw allow 29810:29814/tcp

ufw reload

#install needed files

apt install mongodb -y

apt install jsvc -y

apt install openjdk-8-jre-headless -y

echo "2" | update-alternatives --config java

apt install gdebi-core

#install omada

wget https://static.tp-link.com/upload/software/2023/202309/20230920/Omada_SDN_Controller_v5.12.7_Linux_x64.deb

dpkg -i Omada_SDN_Controller_v5.12.7_Linux_x64.deb

#set cron to reboot the vps every 12 midnight and automatically start the server

echo "1" | crontab -e

0 16 * * * /sbin/reboot

nano /etc/rc.local

(sleep 180; /usr/bin/tpeap stop) &
(sleep 360; /usr/bin/tpeap start) &

chmod +x /etc/rc.local

echo "Setup completed successfully!"
