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
