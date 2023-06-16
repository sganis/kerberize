#!/bin/sh

# tools
yum install -y nmap expect

# kerberos client
yum install -y bind-utils sssd \
	samba-common krb5-workstation \
        openldap-clients ntp

# ssh client and server
yum install -y openssh

# nfs client and server
yum install -y nfs-utils

# cifs client
yum install -y cifs-utils

# web server
yum install -y httpd mod_auth_kerb
