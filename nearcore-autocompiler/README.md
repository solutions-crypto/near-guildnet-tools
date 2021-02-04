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

##### To Compile Nearcore 1.17.0-rc.5 with default settings simply run this command
```
wget https://raw.githubusercontent.com/solutions-crypto/near-guildnet-tools/main/nearcore-autocompile/compiler.sh 
chmod +x install.sh
sudo ./install.sh
```

##### To remove everything except the binary files generated
```
wget https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile/main/clean_up.sh
chmod +x clean_up.sh
sudo ./clean_up.sh
```
##### Container Management
- The container is named "compiler"
- To delete the container "lxc delete compiler -f"
- The cleanup script deletes the container and uninstalls LXD

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

#### Troubleshooting

- You can skip the compile process and just use the installer if you already have the binary file. 

- To start over use the clean_up.sh script
```
wget https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile/main/clean_up.sh
chmod +x clean_up.sh
sudo ./clean_up.sh
```
