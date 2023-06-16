#!/bin/bash

array=(nfs/sys nfs/krb5 nfs/krb5i nfs/krb5p nfs4/sys nfs4/krb5 nfs4/krb5i nfs4/krb5p)
echo "Array size: ${#array[*]}"
echo "Array items:"
for item in ${array[*]}
do
	./benchmark.sh /mnt/$item
done
