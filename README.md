# Guildnet AutoPile

## Overview and Quick Setup

- First compile the source code in a disposable container using the 'compile' script
```
cd $HOME
git clone https://github.com/near-guildnet/guildnet-autopile.git && cd guildnet-autopile
sudo ./compile
```
- Second install the binary files, create a non privilaged account to use, and create the services using the 'install' script
```
sudo ./install
```
- Third delete the container and temporary files _(OPTIONAL)_
```
sudo snap remove lxd --purge
sudo rm -rf /tmp/binaries
sudo rm -rf ~/guildnet-autopile
```

## Detailed Instructions

This script will create a contained environment to safely compile our binary files and then with the clean_up.sh script we destroy the environment when finished with it. 

This keeps our host machine clean of any extra packages that could introduce security issues or unexpected behaviour. It also allows for easy clean up and reproducible builds.

[Docker](https://www.docker.com) does the same thing as [LXD / LXC](https://linuxcontainers.org/) just in a slightly different way. 

This script has the following features.

- Settings to change the github repo url and version at the top
- Detects the host operating system so the binary is compiled using the correct libraries
- New config file to manage advanced behavior of the system journal  
- Option for logging to a file or not
- The cleanup script will remove all tools and files used for the process

The script has 2 parts the compiler and the installer.  
The compiler will run in a container and requires estimated 10gb of space temporarily.  

## Requirements

- Ubuntu (**20.04 focal** or **18.04 bionic**) 
- sudo access
    
## Helpful Info

- Using a newly installed system is preferred.
- The clean_up.sh script will remove everything the compiler does. This is useful if you run into errors from failed previous attempts. 
- The script has been tested using **Ubuntu Cloud Images** 18.04 bionic and 20.04 focal.
- Ubuntu Cloud is preferred/required as it includes cloud-init which is used by LXD/LXC.
- I have tested on Ubuntu 21.04 but only inside of an LXC container. It was very stable and worked well but its not for beginners. Nearcore had no issues running in the environment.
- You will be asked to answer a couple of questions when the scripts start.

# Instructions

### 1. Download the scripts
```
cd $HOME
git clone https://github.com/solutions-crypto/near-guildnet-tools.git
```

### 2. To Compile neard, node exporter, and near exporter with default settings simply run this command
```
sudo /home/$USER/near-guildnet-tools/nearcore-autocompiler/compiler.sh
```

### 3. To install the services
```
sudo /home/$USER/near-guildnet-tools/nearcore-service-setup/install-neard.sh
```

##### To start over
```
chmod +x /home/$USER/near-guildnet-tools/nearcore-autocompiler/clean_up.sh
sudo /home/$USER/near-guildnet-tools/nearcore-autocompiler/clean_up.sh
```


## Install the services

```
sudo ~/near-guildnet-tools/nearcore-service-setup/install-neard.sh
```

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

## Use

### Starting the install script
- ```sudo ./install.sh```

#### Enable the service to start on boot 
- ```sudo systemctl enable /usr/lib/systemd/neard.service```

#### Starting the service (Not required after enabling and restarting)
- ```sudo systemctl start neard-guildnet.service```

#### Stopping the service
- ```sudo systemctl stop neard-guildnet.service```

#### Show service status information
- ```sudo systemctl status near-guildnet.service```

#### Get additional help
- ```sudo systemctl --help```

#### Logging

**By default all logging information is sent to the system journal. For more information see journalctl --help**

To customize how the system journal treats the logged data please see [journald.conf man page](https://manpages.debian.org/testing/systemd/journald.conf.5.en.html)

You could do this for example this will give you the default settings which you can edit.
```
sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.d/neard.conf
sudo nano /etc/systemd/journald.conf.d/neard.conf
```
If you prefer logs to go to a file there is a commented line in /home/neard/service/neard.service remove the # sign. 

** Please note files that are not rotated will eventually fill the hard drive **
```
#StandardOutput=append:/var/log/guildnet.log  
```

- View logs

    - get all unit file records
    ```sudo journalctl -a -u neard ```  

    - get unit file records since boot
    ```sudo journalctl -b -u neard ```  
    
    - follow the unit file journal
    ```sudo journalctl -u neard -f``` 
    
    -  follow the journal
    ```sudo journalctl -f ```
    
    - Get help
    ```journalctl --help```

## Staking Bot
- Please see the [README](https://github.com/solutions-crypto/near-guildnet-tools/blob/main/staking-bot/README.md)

- You can skip the compile process and just use the installer if you already have the binary files the files should be stored in /tmp/binaries/. 

Second install the services

- [neard Installer](https://github.com/solutions-crypto/near-guildnet-tools/tree/main/nearcore-service-setup)

Optionally install the staking bot

- [Staking Bot](https://github.com/solutions-crypto/near-guildnet-tools/tree/main/staking-bot)




