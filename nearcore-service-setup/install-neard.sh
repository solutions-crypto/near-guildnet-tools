#!/bin/bash
# 
# This script was created by # Rickrods @ crypto-solutions.net for the NEAR Guildnet Network
# The script will setup neard as a system service using an unprivilaged user account


set -eu

# Create the new user account and group for the service to use
function create_user_and_group
{
    echo '* Guildnet Install Script Starting'
    echo '* Setting up required accounts, groups, and privilages'

    # Adding group NEAR for any NEAR Services such as Near Exporter

    if grep -q near /etc/group
    then
         echo "group 'near' exists"
    else
         groupadd near
    fi

    # Adding an unprivileged user for the neard service
    if grep -q neard /etc/passwd
    then
         echo "account 'neard' exists"
    else
        adduser --system --home /home/neard --disabled-login --ingroup near neard || true
    fi
}

# Create the system service. It will run with the new account name: neard
function create_neard_service
{
    # Copy the systemd unit file to a suitable location and create a link /etc/systemd/system/neard.service
    mkdir -p /home/neard/service && cd /home/neard/service
    wget https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile/main/neard.service 
    rm -rf /etc/systemd/system/neard.service && sudo ln -s /home/neard/service/neard.service /etc/systemd/system/neard.service
    
    # Extract neard from /tmp/near/nearcore.tar to /usr/local/bin/neard
    cd /tmp/near
    tar -xf nearcore.tar
    cp -p /tmp/near/binaries/neard /usr/local/bin

    # Initialize neard with correct settings
    echo '* Getting the correct files and fixing permissions'
    mkdir -p /home/neard/.near/guildnet && cd /home/neard/.near/guildnet
    neard --home /home/neard/.near/guildnet init --download-genesis --chain-id guildnet --account-id "$VALIDATOR_ID"
    sleep 10
    rm /home/neard/.near/guildnet/config.json && rm /home/neard/.near/guildnet/genesis.json
    wget https://s3.us-east-2.amazonaws.com/build.openshards.io/nearcore-deploy/guildnet/genesis.json
    wget https://s3.us-east-2.amazonaws.com/build.openshards.io/nearcore-deploy/guildnet/config.json
    chown -R neard:near -R /home/neard/

    # Configure Logging
    echo '* Adding logfile conf for neard'
    mkdir -p /usr/lib/systemd/journald.conf.d && cd /usr/lib/systemd/journald.conf.d
    wget https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile/main/neard.conf
    
    # Clean Up
    echo '* Deleting temp files'
    mkdir /home/neard/binaries && cp /tmp/near/binaries/* /home/neard/binaries/
    rm -rf /tmp/near/binaries/
    verify_install
}
