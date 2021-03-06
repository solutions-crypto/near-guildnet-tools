# Configure the Monitor

Note: I always configure the monitor's to use the private network of 10.x.x.x and restrict the ports used to only the local network. There is no good reason to expose this information to the world.

- Step 1  

### Set up a new vps (Ubuntu LTS) to host the grafana server and prometheus 1vcpu and 1gb - 2gb of ram should be enough

- Step 2  

### Use the script to set up the server. 
```
chmod +x monitor.sh
sudo ./monitor.sh
```

- Step 3

### Edit grafana.ini change the ip address and update your smtp settings
```
sudo nano /etc/grafana/grafana.ini
#################################### SMTP / Emailing ##########################
[smtp]
enabled = true
host = mail.my-domain.net:465
user = notifications@my-domain.net
# If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
password = ********
;cert_file =
;key_file =
;skip_verify = false
from_address = notifications@my-domain.net
from_name = Grafana
# EHLO identity in SMTP dialog (defaults to instance_name)
;ehlo_identity = dashboard.example.com
# SMTP startTLS policy (defaults to 'OpportunisticStartTLS')
;startTLS_policy = NoStartTLS
[emails]
welcome_email_on_sign_up = true
;templates_pattern = emails/*.html
```

- Step 4

### Log into grafana using http://MONITOR_IP:3000    

- Add the datasource for prometheus

```
datasource, new, prometheus
http://<MONITOR_IP>:9090/
save
```

- Step 5 

### Add the dashboards

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
