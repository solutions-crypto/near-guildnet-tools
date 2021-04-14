# USE

- Create an Empty Profile and echo the contents from our file.
```
lxc profile create guildnet-cloud
cat cloud-init.yaml | lxc profile edit guildnet-cloud
```

- You need to ensure you also have a profile that contains your container devices I will use default as example
- If you do not see an ethernet device and a root disk device you should add them....
```
lxc profile show default
```

- Use the new cloud profile in combination with the default profile to apply all settings
```
lxc launch images:ubuntu/focal/cloud/amd64 guildnet-validator -p default -p guildnet-cloud
```
