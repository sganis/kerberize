#!/bin/sh
#
# install NFS server

function to_upper() 
{
        echo $1 |tr '[a-z]' '[A-Z]'
}

FOLDER=/support
ADMIN="administrator"
PASSWORD="sant"
DOMAIN=`hostname -d`
HOSTFQDN=`hostname -f`
REALM=`to_upper $DOMAIN`

# add keytab for nfs service
# echo -n "Admin user to add nfs principal in domain:"
# read ADMIN

# create service principal keytab
# this does not work
#net ads keytab add nfs/$HOSTFQDN@$REALM -U $ADMIN 

# the machine has to be re-joined adding a nfs principal
#net ads join -k createupn=nfs/$HOSTFQDN@$REALM -U $ADMIN
# send password unnattended
expect -c "spawn net ads join -k createupn=nfs/$HOSTFQDN@$REALM -U $ADMIN ;expect assword:; send $PASSWORD\r; interact" 
# verify that nfs/fqdn@REALM is added
klist -k 
# this must produce no error
kinit -k nfs/$HOSTFQDN@$REALM

# configure secure nfs
systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl stop rpcbind
systemctl stop nfs-server
systemctl stop nfs-lock
systemctl stop nfs-idmap

# add verbosity to debug, check /var/log/messages
F=/etc/sysconfig/nfs
cp --backup=numbered $F $F.orig
sed -i 's/RPCIDMAPDARGS=""/RPCIDMAPDARGS="-vvv"/' $F
sed -i 's/RPCSVCGSSDARGS=""/RPCSVCGSSDARGS="-vvv"/' $F
#sed -i 's/RPCGSSDARGS=""/RPCGSSDARGS="-vvv"/' $F

systemctl start rpcbind
systemctl start nfs-lock
systemctl start nfs-idmap
systemctl start nfs-server

if [ ! -e $FOLDER ];then
	mkdir $FOLDER
	chmod 777 $FOLDER
fi
echo "$FOLDER  *(rw,no_root_squash,sec=sys:krb5:krb5i:krb5p)" > /etc/exports
exportfs -avr

# configure firewall
# firewall-cmd --permanent --zone=public --add-service=nfs
# firewall-cmd --reload
iptables -F


systemctl enable nfs-secure-server
systemctl stop nfs-secure-server
systemctl start nfs-secure-server


#iptables -I INPUT -m state --state NEW -p tcp \
#    -m multiport --dport 111,892,2049,32769 -s $NETWORK -j ACCEPT
#iptables -I INPUT -m state --state NEW -p udp \
#    -m multiport --dport 111,892,2049,32769 -s $NETWORK -j ACCEPT
#iptables -F


echo Done

