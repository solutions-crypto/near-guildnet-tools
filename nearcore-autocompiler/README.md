## Description

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
- User settings are in the USER SETTINGS section at the top of compilers.sh
- The clean_up.sh script will remove everything the compiler does. This is useful if you run into errors from failed previous attempts. 
- The script has been tested on using Ubuntu Cloud Images 18.04 bionic and 20.04 focal.
- Ubuntu Cloud is preferred as it includes cloud-init which is used by LXD/LXC.
- It has been tested on Ubuntu 21.04 but only inside of an LXC container. It was very stable and worked well but its not for beginners.

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

The file to edit is here. This file includes some notes to help. /usr/lib/systemd/journald.conf.d/neard.conf

If you prefer logs to go to a file uncomment the noted line in the [neard.service](https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile/neard.service) unit file.


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

## After your finished
- The container is named "compiler"
- To delete the container after compiling 
```
lxc delete compiler -f
```
- To delete the temp files 
```
sudo rm -rf /tmp/binaries
rm -rf /home/$USER/near-guildnet/tools
```
- You can skip the compile process and just use the installer if you already have the binary files the should be stored in /tmp/binaries/. 
