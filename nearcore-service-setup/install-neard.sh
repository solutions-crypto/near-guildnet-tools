#!/bin/bash

###############################################################################################
#
#  This script will set up the neard binary as a system service
#
###############################################################################################
echo "*!! NEAR Install Script Starting !!*"
if [ "$USER" != "root" ]
then
    echo " You must run the install script using:  sudo ./install-neard.sh "
    exit
fi
echo "** Please enter the name of the network you wish to connect to betanet, guildnet, mainnet, testnet are all valid **"
read -r NETWORK

echo "** Please your vallidator ID **"
read -r VALIDATOR_ID

echo "** Would you like to install exporter services for prometheus? y/n"
read -r EXPORTERS

# Get the correct config.json
GUILDNET_CONFIG_URL="https://s3.us-east-2.amazonaws.com/build.openshards.io/nearcore-deploy/guildnet/config.json"
GUILDNET_GENESIS_URL="https://s3.us-east-2.amazonaws.com/build.openshards.io/nearcore-deploy/guildnet/genesis.json"


function create_user_and_group
{
echo "* Setting up required accounts, groups, and privilages"
group_check=$(cat /etc/group | grep near)
if [ -z "$group_check" ]
then
sudo groupadd near
else 
echo "The group near already exists"
fi

user_check=$(cat /etc/passwd | grep neard)
if [ -z "$user_check" ]
then
sudo adduser --system --disabled-login --ingroup near --home /home/neard --disabled-password neard
else 
echo "The user neard already exists"
fi
}

function copy_files_set_permissions()
{
# Copy Guildnet Files to a suitable location
sudo mkdir -p /home/neard/.near/guildnet


echo '* Getting the correct files and fixing permissions'
sudo cp /tmp/binaries/near* /usr/local/bin
sudo cp /tmp/binaries/node_exporter /usr/local/bin
sudo neard --home /home/neard/.near/guildnet init --download-genesis --chain-id guildnet --account-id "$VALIDATOR_ID"
sudo wget "$GUILDNET_CONFIG_URL" -O /home/neard/.near/guildnet/config.json
sudo wget "$GUILDNET_GENESIS_URL" -O /home/neard/.near/guildnet/genesis.json
}

function create_exporter_services() 
{
    echo "* Creating systemd unit file for node_exporter service"
    mkdir -p /home/neard/service/
    cat > /home/neard/service/node_exporter.service <<EOF
    [Unit]
    Description=Prometheus Node Exporter
    Documentation=https://github.com/prometheus/node_exporter/blob/master/README.md
    Requires=network-online.target
    [Service]
    Type=exec
    User=exporter
    ExecStart=/var/lib/near/exporter/node_exporter --web.listen-address=":9100"  
    Restart=on-failure
    RestartSec=45
    [Install]
    WantedBy=multi-user.target
EOF

    ln -s /home/neard/service/node_exporter.service /etc/systemd/system/node_exporter.service 
    echo "* Creating systemd unit file for node_exporter service"

    sudo cat > /home/neard/service/near_exporter.service <<EOF
    [Unit]
    Description=NEAR Prometheus Exporter
    Documentation=https://github.com/masknetgoal634/near-prometheus-exporter
    Requires=network-online.target
    [Service]
    Type=simple
    User=exporter
    ExecStart=/usr/local/bin/near_exporter -accountId "$VALIDATOR_ID" -addr ":9333"
    Restart=on-failure
    RestartSec=45
    [Install]
    WantedBy=multi-user.target
EOF
    sudo ln -s /home/neard/service/near_exporter.service /etc/systemd/system/near_exporter.service
}

function create_neard_service()
{ 
echo "* Creating systemd unit file for NEAR validator service"
mkdir -p /home/neard/service/
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
ExecStart=/usr/local/bin/neard --home /home/neard/.near/guildnet run
Restart=on-failure
RestartSec=80
#StandardOutput=append:/var/log/guildnet.log
[Install]
WantedBy=multi-user.target
EOF

ln -s /home/neard/service/neard.service /etc/systemd/system/neard.service
}

function create_journald_conf()
{ 
    echo '* Adding journald conf for neard'
    sudo mkdir -p /usr/lib/systemd/journald.conf.d
    sudo cat > /usr/lib/systemd/journald.conf.d/neard.conf <<EOF
    #  This file is part of systemd
    #
    # This file controls the logging behavior of the service
    # You can change settings by editing this file.
    # Defaults can be restored by simply deleting this file.
    # Uncomment to make changes. the original is in /etc
    # See journald.conf(5) for details. This is the link. 
    # https://manpages.debian.org/testing/systemd/journald.conf.5.en.html
    [Journal]
    # Storage Controls where to store journal data
    # Valid options: "volatile", "persistent", "auto" or "none"
    #Storage=auto
    # Control whether log messages received by the journal daemon shall be forwarded to a traditional syslog daemon, to the kernel log buffer (kmsg), to the system console, or sent as wall messages to all logged-in users
    # Accepts boolean value
    ForwardToSyslog=no
    #ForwardToKMsg=
    #ForwardToConsole= 
    #ForwardToWall=
    # Controls the maximum log level of messages that are stored in the journal, forwarded to syslog, kmsg, the console or wall
    # As argument, takes one of "emerg", "alert", "crit", "err", "warning", "notice", "info", "debug", or integer values in the range of 0–7 (corresponding to the same levels)
    #MaxLevelStore=
    #MaxLevelSyslog=
    #MaxLevelKMsg=
    #MaxLevelConsole=
    #MaxLevelWall=
    # Accepts a boolean value.
    #Compress=yes
    # Takes a boolean value requires a seal key
    #Seal=yes
    # Controls whether to split up journal files per user
    #SplitMode=uid
    # The maximum time to store entries in a single journal file before rotating to the next one
    #MaxFileSec=
    # The maximum time to store journal entries
    #MaxRetentionSec=
    # The timeout before synchronizing journal files to disk
    #SyncIntervalSec=6m
    # If, in the time interval defined by RateLimitIntervalSec more messages than specified in RateLimitBurst 
    # are logged by a service, all further messages within the interval are dropped until the interval is over
    # Set either value to 0 to disable. 
    # Note that the effective rate limit is multiplied by a factor derived from the available free disk space for the journal. 
    # Currently, this factor is calculated using the base 2 logarithm.
    #RateLimitInterval=30m
    #RateLimitBurst=1000
    # Enforce size limits on the journal files stored
    #SystemMaxUse= 
    #SystemKeepFree= 
    #SystemMaxFileSize= 
    #SystemMaxFiles= 
    #RuntimeMaxUse= 
    #RuntimeKeepFree= 
    #RuntimeMaxFileSize= 
    #RuntimeMaxFiles=
    # These all accept boolean value see link at top
    #ReadKMsg=
    #Audit=
    #TTYPath=
    #LineMax=
EOF
systemctl restart systemd-journald
}

create_user_and_group

if [ "$EXPORTERS" = y ]
then
create_exporter_services
fi

create_neard_service
create_journald_conf
copy_files_set_permissions
sudo chown neard:near -R /home/neard/

echo '****   You should restart the machine now due to changes made to the logging system then check your validator key'
echo '****   You can enable the services installed using the following commands'
echo '****   "systemctl enable neard" "systemctl enable node_exporter" "systemctl enable near_exporter" '
