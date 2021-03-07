#!/bin/bash

if [ "$USER" != "root" ]
then
    echo " You must run the install script using:  sudo ./monitor.sh "
    exit
fi

#echo "Please enter the ip address of your validator"
#read VALIDATOR_IP

#echo "Please enter the monitor IP address"
#read MONITOR_IP

function create_user_and_group()
{
    echo "* Setting up required accounts, groups, and privilages"
    group_check=$(cat /etc/group | grep prometheus)
    if [ -z "$group_check" ]
    then
        sudo groupadd prometheus
    else 
        echo "The group near already exists"
    fi

    user_check=$(cat /etc/passwd | grep prometheus)
    if [ -z "$user_check" ]
    then
        sudo adduser --system --disabled-login --ingroup prometheus --home /home/prometheus --disabled-password prometheus
    else 
        echo "The user prometheus already exists"
    fi
}

function create_prometheus_service() 
{
    echo "* Creating systemd unit file for Prometheus service"
    mkdir -p /etc/prometheus/
    cat > /etc/prometheus/prometheus.service <<EOF
    [Unit]
    Description=Prometheus Service
    After=network.target
    [Service]
    User=root
    Type=simple 
    Restart=on-failure
    ExecStart=/usr/local/bin/prometheus --config.file="/etc/prometheus/prometheus.yml" --web.listen-address="0.0.0.0:9090"
    [Install]
    WantedBy=multi-user.target
EOF

    ln -s /etc/prometheus/prometheus.service /etc/systemd/system/prometheus.service
}

function install_grafana()
{
    sudo apt-get install -y apt-transport-https software-properties-common wget
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
    sudo apt-get update
    sudo apt-get install grafana
}

function install_prometheus()
{
    mkdir -p /tmp/monitor && cd /tmp/monitor
    wget https://github.com/prometheus/prometheus/releases/download/v2.25.0/prometheus-2.25.0.linux-amd64.tar.gz
    HASH_CHECK=$(sha256sum prometheus-2.25.0.linux-amd64.tar.gz)
    CORRECT='d163e41c56197425405e836222721ace8def3f120689fe352725fe5e3ba1a69d  prometheus-2.25.0.linux-amd64.tar.gz'
    echo "HASH: $HASH_CHECK "
    echo "GOOD: $CORRECT "
    if [[ $HASH_CHECK != $CORRECT ]]
    then
        echo "The download file has the incorrect hash aborting..."
        exit
    else
        tar -xf prometheus-2.25.0.linux-amd64.tar.gz
        cd prometheus-2.25.0.linux-amd64/
        sudo cp prometheus /usr/local/bin/prometheus
    fi
}

function create_prometheus_yml()
{
    mkdir -p /etc/prometheus && cd /etc/prometheus
    rm prometheus.yml
    wget https://raw.githubusercontent.com/solutions-crypto/near-guildnet-tools/main/monitor/prometheus.yml
    cd ~/
    chown -R prometheus:root /etc/prometheus
}

function enable_services()
{
    systemctl daemon-reload
    systemctl enable prometheus
    systemctl enable grafana-server
    systemctl start prometheus
    systemctl start grafana-server
}



create_user_and_group
create_prometheus_service
install_grafana
install_prometheus
create_prometheus_yml
enable_services
echo " You need to update the ip addresses in /etc/prometheus/prometheus.yml and /etc/systemd/system/prometheus.service"
