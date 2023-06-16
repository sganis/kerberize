#!/bin/bash
#
# IPA server

# firewall
echo "Configuring firewall..."
systemctl enable firewalld.service
# block ldap to domain crontroller
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.100.100" service name="ldap" reject'
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.100.100" service name="ldaps" reject'
# open services for IdM
firewall-cmd --permanent --zone=public --add-port={80/tcp,443/tcp,389/tcp,636/tcp,88/tcp,464/tcp,53/tcp,88/udp,464/udp,53/udp,123/udp}
# open ports for trust
firewall-cmd --permanent --zone=public --add-port={138/tcp,139/tcp,445/tcp,138/udp,139/udp,389/udp,445/udp}
firewall-cmd --reload


# create groups
ipa group-add --desc='AD users external map' ad_users_external --external
ipa group-add --desc='AD users' ad_users
ipa group-add-member ad_users_external --external "TEST\Domain Users"
ipa group-add-member ad_users --groups ad_users_external