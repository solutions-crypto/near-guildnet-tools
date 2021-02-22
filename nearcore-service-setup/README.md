# Install

NOTE: You must have at minimum the neard binary file you want to use compiled to run this script. This script will check /tmp/binaries/ for the files it requires. If they are unavailable the script will be unable to complete successfully.

## Instructions

./installer.sh

After the script has run you will have 3 additional services

- neard
- near_exporter
- node_exporter

You need to configure them then you can start them using systemctl 
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
