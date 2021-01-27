#!/bin/bash

###############################################################################################
#
#  This script will set up the neard binary as a system service
#
###############################################################################################
echo "*!! NEAR Install Script Starting !!*"
echo "** Please enter the name of the network you wish to connect to betanet, guildnet, mainnet, testnet are all valid **"
read NETWORK

# Get the correct config.json
GUILDNET_CONFIG_URL="https://s3.us-east-2.amazonaws.com/build.openshards.io/nearcore-deploy/guildnet/config.json"
GUILDNET_GENESIS_URL="https://s3.us-east-2.amazonaws.com/build.openshards.io/nearcore-deploy/guildnet/genesis.json"

echo "* Setting up required accounts, groups, and privilages"
group_check=$(cat /etc/group | grep near)
if [ -z "$group_check" ]
then
sudo groupadd near
else 
echo "The group near already exists"

user_check=$(cat /etc/passwd | grep neard)
if [ -z "$user_check" ]
then
sudo adduser --system --disabled-login --ingroup near --home /home/neard --disabled-password neard
else 
echo "The user neard already exists"


# Copy Guildnet Files to a suitable location
sudo mkdir -p /home/neard/.near/guildnet
sudo mkdir -p /home/neard/.neard-service

sudo cp -p /tmp/near/neard /usr/local/bin

echo '* Getting the correct files and fixing permissions'
sudo neard --home /home/neard/.near/guildnet init --download-genesis --chain-id guildnet --account-id $VALIDATOR_ID
sudo wget $CONFIG_URL -O /home/neard/.near/guildnet/config.json
sudo wget $GENESIS_URL -O /home/neard/.near/guildnet/genesis.json
sudo chown neard:near -R /home/neard/

echo "* Creating systemd unit file for NEAR validator service"

sudo cat > /home/neard/service/neard.service <<EOF
[Unit]
Description=NEAR Validator Service
Documentation=https://github.com/nearprotocol/nearcore
Wants=network-online.target
After=network-online.target

[Service]
Type=exec
User=neard
Group=near
ExecStart=neard --home /home/neard/.near/guildnet run
Restart=on-failure
RestartSec=80
#StandardOutput=append:/var/log/guildnet.log

[Install]
WantedBy=multi-user.target
EOF

ln -s /home/neard/service/neard.service /etc/systemd/system/neard.service

echo '* Adding logfile conf for neard'
sudo mkdir -p /usr/lib/systemd/journald.conf.d
sudo cat > /usr/lib/systemd/journald.conf.d/neard.conf <<EOF
#  This file is part of systemd
#
# This file controls the logging behavior of the service
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See journald.conf(5) for details.
[Journal]
Storage=auto
ForwardToSyslog=no
Compress=yes
#Seal=yes
#SplitMode=uid
SyncIntervalSec=1m
RateLimitInterval=30s
#RateLimitBurst=1000
EOF

echo '* Service Status 'sudo systemctl status neard.service' *'
sudo systemctl enable neard.service
sudo systemctl status neard.service

echo '* The installation has completed removing the installer'
lxc stop compiler
lxc delete compiler
#sudo snap remove --purge lxd
rm -rf /tmp/near

echo '* You should restart the machine now due to changes made to the logging system then check your validator key'
