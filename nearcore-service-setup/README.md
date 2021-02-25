# Install

NOTE: You must have at minimum the neard binary file you want to use compiled to run this script. This script will check /tmp/binaries/ for the files it requires. If they are unavailable the script will be unable to complete successfully.

## Instructions

sudo ./installer.sh

After the script has run you will have 3 additional services

- neard
- near_exporter
- node_exporter

### You first need to configure the services 
- To configure **neard**

Uncomment the commented line to append output to a file

To see all options available use neard run --help any flag here can be entered on the line starting with Exec

If you are specifying advanced networking options you should edit /home/$USER/.near/guildnet/config.json
```
sudo nano /home/neard/services/neard.service
```

- To configure **near_exporter**

This is a modified install of [Near Prometheus Exporter](https://github.com/masknetgoal634/near-prometheus-exporter) where we do not use docker and compile the sources locally to run the service.
```
sudo nano /home/services/near_exporter.service
```
This line should have your pool id and theip address to listen on. *example* 
```
    ExecStart=/usr/local/bin/near_exporter -accountId "testing.stake.guildnet" -addr "8.8.8.8:9333"
```

- To configure **node_exporter**
Documentation is located [on the prometheus website](https://prometheus.io/docs/guides/node-exporter/) or [Github](https://github.com/prometheus/node_exporter)
```
sudo nano /home/services/node_exporter.service
```

then you can start them using systemctl 
- Examples:  
```
systemctl enable neard 
systemctl start neard 
systemctl status neard
```

Logging 
- Follow the system journal for the -u unit file neard
```
sudo journalctl -u neard -f
```
- Get all logs for the system
```
sudo journalctl -a
```
- Get help
```
journalctl -h
```
