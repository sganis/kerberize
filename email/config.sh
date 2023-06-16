#!/bin/bash
DOMINIO=$(cat ./admail.conf | egrep '^dominio' |cut -d"=" -f2 |sed 's/ //')
USUARIO=$(cat ./admail.conf | egrep '^usuario' |cut -d"=" -f2 |sed 's/ //')
PASSWORD=$(cat ./admail.conf | egrep '^password' |cut -d"=" -f2 |sed 's/ //')
SERVER=$(cat ./admail.conf | egrep '^server_ldap' |cut -d"=" -f2 |sed 's/ //')
ldap_bind_dn=$USUARIO@$DOMINIO
ldap_domain=dc=$(echo $DOMINIO |sed -e 's/\./,dc=/g')
ldap_search_base=cn=users,$ldap_domain
hostname=$(hostname -f)

echo $DOMINIO
echo $ldap_domain
echo $ldap_search_base
echo $ldap_bind_dn
echo $PASSWORD

# dovecot
sed -i "s/postmaster_address = .\+/postmaster_address = $ldap_bind_dn/" ./dovecot.conf
sed -i "s/hosts = .\+/hosts = $SERVER/" ./dovecot-ldap.conf
sed -i "s/base = .\+/base = $ldap_domain/" ./dovecot-ldap.conf
sed -i "s/dn = .\+/dn = $ldap_bind_dn/" ./dovecot-ldap.conf
sed -i "s/dnpass = .\+/dnpass = $PASSWORD/" ./dovecot-ldap.conf

# postfix
sed -i "s/^myhostname = .\+/myhostname = $hostname/" ./main.cf
sed -i "s/^mydomain = .\+/mydomain = $DOMINIO/" ./main.cf
sed -i "s/^ldap_bind_dn = .\+/ldap_bind_dn = $ldap_bind_dn/" ./main.cf
sed -i "s/^ldap_bind_pw = .\+/ldap_bind_pw = $PASSWORD/" ./main.cf
sed -i "s/^ldap_domain = .\+/ldap_domain = $ldap_domain/" ./main.cf
sed -i "s/^ldap_search_base = .\+/ldap_search_base = $ldap_search_base/" ./main.cf
sed -i "s/^ldap_server_host = .\+/ldap_server_host = $SERVER/" ./main.cf

cp ./main.cf ./master.cf /etc/postfix
cp ./dovecot.conf ./dovecot-ldap.conf /etc/dovecot

/etc/init.d/postfix restart
/etc/init.d/dovecot restart

nmap localhost
