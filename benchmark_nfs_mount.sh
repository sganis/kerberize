#!/bin/bash

mkdir -p /mnt/nfs/sys
mkdir -p /mnt/nfs/krb5
mkdir -p /mnt/nfs/krb5i
mkdir -p /mnt/nfs/krb5p
chmod -R 777 /mnt/nfs
mkdir -p /mnt/nfs4/sys
mkdir -p /mnt/nfs4/krb5
mkdir -p /mnt/nfs4/krb5i
mkdir -p /mnt/nfs4/krb5p
chmod -R 777 /mnt/nfs4

mount -t nfs -o vers=3 192.168.1.155:/support /mnt/nfs/sys
mount -t nfs -o vers=3 -o sec=krb5 192.168.1.155:/support /mnt/nfs/krb5
mount -t nfs -o vers=3 -o sec=krb5i 192.168.1.155:/support /mnt/nfs/krb5i
mount -t nfs -o vers=3 -o sec=krb5p 192.168.1.155:/support /mnt/nfs/krb5p
mount -t nfs4 192.168.1.155:/support /mnt/nfs4/sys
mount -t nfs4 -o sec=krb5 192.168.1.155:/support /mnt/nfs4/krb5
mount -t nfs4 -o sec=krb5i 192.168.1.155:/support /mnt/nfs4/krb5i
mount -t nfs4 -o sec=krb5p 192.168.1.155:/support /mnt/nfs4/krb5p



