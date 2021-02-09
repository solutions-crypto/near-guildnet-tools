## Near Validator Stake management and Monitoring


- Tools Needed

  1. near-cli
  2. Postfix

 **Optional**

  1. Grafana Server

  2. Prometheus Server


- Set Up Postfix [source](https://www.dlford.io/send-email-alerts-from-linux-server/)
```
sudo apt install -y postfix mailutils libsasl2-modules
sudo nano /etc/postfix/sasl_passwd
```
Enter a server and account that permits you to send mail
```
[smtp.gmail.com]:587 username@gmail.com:password
```
The postmap command will convert our text file into a lookup table, which is a data format that postfix can quickly and efficiently parse for data.
```
postmap /etc/postfix/sasl_passwd
```

Since these two files contain your Gmail password, it is wise to lock down their permissions so only the root user can access their contents.
```
chown root. /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
chown root. /etc/postfix/sasl_passwd.db
chmod 600 /etc/postfix/sasl_passwd.db
```

We need to set up aliases and virtual alias maps, aliases will redirect mail from one user to another on the same host, for example from postmaster@ServerHostName to root@ServerHostName, we will direct all Email to root here. Virtual alias maps complete the picture by redirecting mail from local users on this host to an external Email address.

```
sudo nano etc/aliases
```

You should run the command newaliases after changing this file so it will be parsed appropriately. You can add any other local users that may receive mail to this list.
```
sudo newaliases
```
The Email address here is where any mail will be directed.
```
sudo nano /etc/postfix/virtual
```
  ```root you@yourdomain.com```

The virtual alias map file also needs to be post mapped.

```
postmap /etc/postfix/virtual
```

In the main configuration file for postfix, update the values for the following lines, if a line is missing from your configuration file you’ll just need to add the whole line.

```
sudo nano /etc/postfix/main.cf
```
These settings tell postfix to use Gmail as a relay to send mail out, and then specify the parameters and credentials for connecting to Gmail.
```
relayhost = [smtp.gmail.com]:587
smtp_tls_security_level = may
smtp_sasl_auth_enable = yes
smtp_sasl_security_options =
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
```

These settings are for aliasing as explained above
```
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
virtual_alias_maps = hash:/etc/postfix/virtual
```
I also remove all the values from mydestination, this tells postfix it is not to receive any mail on this system, it will only send it out the relay host or reject the message.
```
mydestination =
```
If you do not have IPv6 enabled, you will need to specify the following value in main.cf as well, often DNS queries for Gmail will return the IPv6 address first, and postfix will fail to send mail because the relay host is unreachable.
```
inet_protocols = ipv4
```
Restart postfix to apply the configuration.
```
systemctl restart postfix
```
