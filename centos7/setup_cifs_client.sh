#!/bin/sh

# setup cifs client to access windows shares

yum install cifs-utils

mkdir /mnt/windows
mount.cifs \\\\dc\\Company /mnt/windows -o sec=krb5 -o user=administrator
