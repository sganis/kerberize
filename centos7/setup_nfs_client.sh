#!/bin/bash

function to_upper() 
{
        echo $1 |tr '[a-z]' '[A-Z]'
}

FOLDER=/support
ADMIN=Administrator
PASSWORD="Password1"
DOMAIN=`hostname -d`
HOSTFQDN=`hostname -f`
REALM=`to_upper $DOMAIN`

# the machine has to be re-joined adding a nfs principal
#net ads join -k createupn=nfs/$HOSTFQDN@$REALM -U $ADMIN
# send password unnattended
expect -c "spawn net ads join -k createupn=nfs/$HOSTFQDN@$REALM -U $ADMIN ;expect assword:; send $PASSWORD\r; interact" 
# verify that nfs/fqdn@REALM is added
klist -k 
# this must produce no error
kinit -k nfs/$HOSTFQDN@$REALM


SERVER=box1.test.com
EXPORT=/support

systemctl enable nfs-idmap
systemctl enable nfs-secure
systemctl stop nfs-idmap
systemctl stop nfs-secure
systemctl start nfs-idmap
systemctl start nfs-secure

# add verbosity to debug, check /var/log/messages
F=/etc/sysconfig/nfs
cp --backup=numbered $F $F.orig
sed -i 's/RPCIDMAPDARGS=""/RPCIDMAPDARGS="-vvv"/' $F
#sed -i 's/RPCSVCGSSDARGS=""/RPCSVCGSSDARGS="-vvv"/' $F
sed -i 's/RPCGSSDARGS=""/RPCGSSDARGS="-vvv"/' $F

systemctl restart nfs-idmap
systemctl restart nfs-secure

umount /mnt/sys
umount /mnt/krb5
umount /mnt/krb5i
umount /mnt/krb5p


echo "Making direcories"
mkdir -p /mnt/sys
mkdir -p /mnt/krb5
mkdir -p /mnt/krb5i
mkdir -p /mnt/krb5p
chmod -R 777 /mnt/*

echo "Mounting..."
mount -t nfs4 $SERVER:/support /mnt/sys
mount -t nfs4 -o sec=krb5 $SERVER:$EXPORT /mnt/krb5
mount -t nfs4 -o sec=krb5i $SERVER:$EXPORT /mnt/krb5i
mount -t nfs4 -o sec=krb5p $SERVER:$EXPORT /mnt/krb5p



