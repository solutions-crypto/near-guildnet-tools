#!/bin/bash

# Get Prometheus Node Exporter and extract the binary to /usr/loca/bin
#wget -P /tmp/ https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
#tar -xzf node_exporter-1.0.1.linux-amd64.tar.gz node_exporter-1.0.1.linux-amd64/node_exporter
#sudo cp /tmp/node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin

if grep -q monitoring /etc/group
then
        echo "group 'monitoring' exists"
else
        groupadd monitoring
fi

# Adding an unprivileged user for the exporter services
if grep -q exporter /etc/passwd
then
        echo "account 'exporter' exists"
else
    adduser --system --home /home/exporter --disabled-login --ingroup monitoring exporter || true
fi
# Create the unit file
sudo cat > /etc/systemd/system/node_exporter.service <<EOF

[Unit]
Description=Prometheus Node Exporter Service
After=network.target

[Service]
User=exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address="<SERVER_IP>:9100"

[Install]
WantedBy=multi-user.target
EOF


# Compile Near Prometheus Exporter to work outside of docker
git clone https://github.com/masknetgoal634/near-prometheus-exporter.git
go build -a -installsuffix cgo -ldflags="-w -s" -o main .




# Clean Up
rm -rf /tmp/node*



