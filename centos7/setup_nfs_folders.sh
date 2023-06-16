#!/bin/sh
# nfs 16 group limit
# run as root

FOLDER=/support

if [ $# -lt 1 ];then
	echo "usage: $0 user [dirs=33]"
	exit
fi
USER=$1
NUM=33
LEN=2
if [ $# -gt 1 ];then
	NUM=$2
fi
if [ $# -gt 2 ];then
	LEN=$3
fi

# create folders
for i in `seq -f "%0${LEN}g" 1 $NUM`; do
	g=g$i	
	[ -d $g ] || mkdir $FOLDER/$g
	chgrp $g $FOLDER/$g
	chmod 070 $FOLDER/$g
done

cp test_nfs_access.sh $FOLDER
chmod 755 $FOLDER/test_nfs_access.sh

echo Done.

