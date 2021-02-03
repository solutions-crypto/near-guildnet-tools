#!/bin/bash

wget -P /tmp/ https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar -xzf node_exporter-1.0.1.linux-amd64.tar.gz node_exporter-1.0.1.linux-amd64/node_exporter
sudo cp /tmp/node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin


# Copy the unit file
   cat <<EOF | /etc/systemd/system/node_exporter.service
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






# Clean Up
rm -rf /tmp/node*



