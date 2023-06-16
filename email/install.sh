#!/bin/bash

apt-get update
apt-get -y install \
	postfix postfix-ldap \
	dovecot-common dovecot-imapd dovecot-pop3d \
	nmap htop ccze

# usuario vmail con id 5000
addgroup --gid 5000 vmail
useradd -m --uid 5000 --gid 5000 vmail
chown root.root /var/log/mail.*
chmod 755 ./config.sh
./config.sh
