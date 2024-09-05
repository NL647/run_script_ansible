#!/usr/bin/env bash

#debug
#set -x

echo -e "================================="
echo -e "Installing unattended-upgrades..."
echo -e "================================="
lsb_relase -a || >&2

sudo apt update
sudo apt-get install unattended-upgrades -y
sudo echo "unattended-upgrades       unattended-upgrades/enable_auto_updates boolean true"\
| sudo debconf-set-selections && sudo dpkg-reconfigure -f noninteractive unattended-upgrades || echo -e "Error installing package...."

echo -e "================================="
echo -e "DONE..."
echo -e "================================="

exit 0
