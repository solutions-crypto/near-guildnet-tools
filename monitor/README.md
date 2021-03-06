# Configure the Monitor

Note: I always configure the monitor's to use the private network of 10.x.x.x and restrict the ports used to only the local network. There is no good reason to expose this informationi to the world.

- Step 1  

Set up a new vps (Ubuntu LTS) to host the grafana server and prometheus 1vcpu and 1gb - 2gb of ram should be enough

- Step 2  

Use the script to set up the server. 
```
chmod +x monitor.sh
sudo ./monitor.sh
```

- Step 3

Log into grafana using http://MONITOR_IP:3000    

- Add the datasource for prometheus

```
datasource, new, prometheus
http://<MONITOR_IP>:9090/
save
```

- Step 4 

Add the dashboards

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
