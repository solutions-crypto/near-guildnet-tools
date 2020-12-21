## Description

This script will create a contained environment where we can build our binary files and then with the clean_up.sh script we destroy the environment when finished with it. We could do many different things depending on our environment. For example you could modify the script to export the container to a file located on a network drive so it could be used again the next time we need to compile. 

If you are already using LXD this script will reset your init settings. If this may cause problems you should comment out or delete the [lxd init section](https://github.com/solutions-crypto/nearcore-autocompile/blob/main/install.sh#L61) that runs lxd init... ( lines 61-99 )

This keeps our host machine clean of any extra packages that could introduce security issues or unexpected behaviour. It also allows for easy clean up.

Docker does the same thing as LXD / LXC just in a slightly different way. Our script will do the following 

- Compile any version input for guildnet 
- Creates a lxc container to compile the binaries and exports a tar file with binaries back to the host
- Sets up the host machine to run the binaries using systemd 
- Creates a neard system service that runs with a non-privilaged system account
- Configures a new guildnet validator with config, genesis, and keys
- Options for logging
- Removes everything installed for the compile process if requested

The script has 2 parts the compiler and the installer. This will automate the compile process and could easily simplify the install process. The compiler will run in a container and installs a large amount of softare over 1.5gb so please be sure to have pleny of space.   

## Requirements

- Ubuntu (**20.04 focal** or **18.04 bionic**) 
- sudo access
    
## Instructions

- The install script will create the directories, user account, systemd service, and set the permissions for you. 
- Ubuntu should be set up and you should run the script using sudo from your users account.
- This script can be used to compile any version of nearcore from any repo you specify see lines 8 thru 11 of [install.sh](https://github.com/solutions-crypto/nearcore-autocompile/install.sh)
- You can remove everything and start over using the clean_up.sh script --- can be useful if you run into problems.
- When answering question use y for Yes and anything else is no
- The script will detect your operating system and build using the same ubuntu release. 
- The script has been tested on ubuntu 18 and 20. It has been tested on 21.04 only when used inside of a container so far. It is possible to compile on 21.04 then launch a container and use lxc file push to copy the tar file to /tmp/near and install script to /tmp/near then run the script to install the service inside the container. If you will be using containers regularly you might need some additional apparmor setup ["apparmor-profiles apparmor-profiles-extra"](https://wiki.debian.org/AppArmor/HowToUse#Enabling_profiles)

##### To Install
```
wget https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile/install.sh
chmod +x install.sh
sudo ./install.sh
```

##### To remove
```
wget https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile/clean_up.sh
chmod +x clean_up.sh
sudo ./clean_up.sh
```
##### To re-user a container 
- The container should be named "compiler"
- edit install.sh
- There are 2 lines that contain "launch_container" comment out the one that contains only that phrase. 
- This will prevent the script from trying to create a new container to use and the existing container named compiler will be used.

The install script has an option to enter the validator name so the validator key is generated correctly


## Use

### Starting the install script
- ```sudo ./install.sh```

#### Enable the service to start on boot 
- ```sudo systemctl enable /usr/lib/systemd/neard.service```

#### Starting the service
- ```sudo systemctl start neard-guildnet.service```

#### Stopping the service
- ```sudo systemctl stop neard-guildnet.service```

#### Show service status information
- ```sudo systemctl status near-guildnet.service```

#### Get additional help
- ```sudo systemctl --help```

#### Logging

**By default all logging information is sent to the system journal. For more information see journalctl --help**

If you prefer logs to go to a file uncomment the noted line in the [neard.service](https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile/neard.service) unit file.


- View logs

    - get all unit file records
    ```sudo journalctl -a -u neard ```  
    
    - follow the unit file journal
    ```sudo journalctl -u neard -f``` 
    
    -  follow the journal
    ```sudo journalctl -f ```
    
    - Get help
    ```journalctl --help```

#### Troubleshooting

- If the script fails verify you have the tar file in the correct place
```
ls /tmp/near/nearcore.tar
```

If you have /tmp/near/nearcore.tar you can skip the compile process. 

- To start over use the clean_up.sh script
```
wget https://raw.githubusercontent.com/solutions-crypto/nearcore-autocompile//clean_up.sh
chmod +x clean_up.sh
sudo ./clean_up.sh
```
