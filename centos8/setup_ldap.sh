#!/bin/sh

dnf install -y sssd sssd-tools sssd-ldap openldap-clients
sudo ldapsearch -H ldaps://contoso.com -x \
        -D CN=ldapuser,CN=Users,DC=contoso,DC=com -w ldapuserpassword \
        -b CN=Users,DC=contoso,DC=com

cp etc-sssd-sssd.conf /etc/sssd
chmod 600 /etc/sssd/sssd.conf

# create obfuscated password
# sss_obfuscate --domain default
# systemctl start sssd
# authconfig --enablesssd --enablesssdauth --enablemkhomedir --updateall
# systemctl restart sssd

