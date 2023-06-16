#!/bin/bash

umount /mnt/nfs/sys
umount /mnt/nfs/krb5
umount /mnt/nfs/krb5i
umount /mnt/nfs/krb5p
umount /mnt/nfs4/sys
umount /mnt/nfs4/krb5
umount /mnt/nfs4/krb5i
umount /mnt/nfs4/krb5p
rm -rf /mnt/nfs*


