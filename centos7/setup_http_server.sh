#!/bin/bash

function to_upper() 
{
        echo $1 |tr '[a-z]' '[A-Z]'
}

ADMIN="administrator"
PASSWORD="sant"
DOMAIN=`hostname -d`
HOSTFQDN=`hostname -f`
REALM=`to_upper $DOMAIN`

# the machine has to be re-joined adding a nfs principal
#net ads join -k createupn=nfs/$HOSTFQDN@$REALM -U $ADMIN
# send password unnattended
expect -c "spawn net ads join -k createupn=HTTP/$HOSTFQDN@$REALM -U $ADMIN;
expect assword:; 
send $PASSWORD\r; interact" 

# verify that nfs/fqdn@REALM is added
klist -k 
# this must produce no error
kinit -k HTTP/$HOSTFQDN@$REALM

# httpd
F=/etc/httpd/conf.d/auth_kerberos.conf
cp --backup=numbered etc-httpd-conf.d-auth_kerberos.conf $F
sed -i "s/EXAMPLE.COM/$REALM/" $F
chmod 644 /etc/krb5.keytab 
systemctl restart httpd

# firewall
iptables -F

# test page
# mkdir /var/www/html/kerberos
F=/var/www/html/index.html
cp -v --backup=numbered $F $F.backup
echo "<html><body>Kerberos test page<br/>" > $F
echo "To see if it works, click this link: <a href=\"/cgi-bin/kerberos.sh\">Test script</a>" >> $F
echo "</body></html>" >> $F
cp -v var-www-cgi-bin-kerberos.sh /var/www/cgi-bin/kerberos.sh

# configure IE
# Turn on "Windows Integrated Authentification" in advanced settings
# add the site to intranet 
# use http://fqdn/kerberos, it shouldn't ask for password.

# configure Firefox
# about:config
# enter the domain in network.negotiate-auth.trusted-uris