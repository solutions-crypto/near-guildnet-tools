# Configure the Monitor

- Step 1 

Set up a new vps (Ubuntu LTS) to host the grafana server and prometheus 1vcpu and 1gb - 2gb of ram should be enough

- Step 2

Install Grafana [Source](https://grafana.com/docs/grafana/latest/installation/debian/)

```
sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.li
sudo apt-get update
sudo apt-get install grafana
```

- Step 3

Install Prometheus [Source]()

```
wget https://github.com/prometheus/prometheus/releases/download/v2.25.0/prometheus-2.25.0.linux-amd64.tar.gz
sha256sum prometheus-2.25.0.linux-amd64.tar.gz
# STOP. verify the hash matches d163e41c56197425405e836222721ace8def3f120689fe352725fe5e3ba1a69d
tar -xf prometheus-2.25.0.linux-amd64.tar.gz
cd prometheus-2.25.0.linux-amd64/
sudo mkdir -p /etc/prometheus/
sudo cp * /etc/prometheus/
cd /etc/prometheus
sudo rm -rf ~/prometheus-2.25.0.linux-amd64/
sudo nano prometheus.yml
```

prometheus.yml
```
# my global config
# This file assumes the monitor node is localhost and the near node is on 10.0.0.5 
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  # This job monitors the prometheus service on localhost
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

  # This job is for all node-exporters
  - job_name: 'node-exporter'
    static_configs:
    - targets: ['10.0.0.5:9100']

  # This job monitors near-exporter
  - job_name: 'near-exporter'
    static_configs:
    - targets: ['10.0.0.5:9333']
```

- Create the prometheus service

```
sudo nano /etc/prometheus/prometheus.service
```
prometheus.service
```
[Unit]
Description=Prometheus Service
After=network.target

[Service]
User=root
Type=simple
Restart=always
RestartSec=15
ExecStart=/etc/prometheus/prometheus --config.file="/etc/prometheus/prometheus.yml" --storage.tsdb.retention.size="10GB" --web.listen-address="10.0.0.4:9090"


[Install]
WantedBy=multi-user.target
```

```
sudo systemctl enable prometheus.service
sudo systemctl enable grafana-server 
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl start grafana-server
sudo systemctl status grafana-server
sudo systemctl status prometheus
```

Log into grafana using http://MONITOR_IP:3000    

- Add the datasource for prometheus

```
datasource, new, prometheus
http://localhost:9090/
save
```

- Add the dashboards

Node Exporter
```
import dashboard
grafana id 1860
```

Near Exporter [Dashboard File Download](wget https://raw.githubusercontent.com/crypto-guys/near-prometheus-exporter/master/etc/grafana/dashboards/near-node-exporter-full.json)
```
download the file in the link. 
import dashboard
select Upload JSON and use the downloaded file
```
