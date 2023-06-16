#!/bin/sh
# nfs 16 group limit
# run as root

if [ $# -lt 1 ];then
	echo "usage: $0 user [dirs=20]"
	exit
fi
USER=$1
NUM=20
LEN=2
if [ $# -gt 1 ];then
	NUM=$2
fi
if [ $# -gt 2 ];then
	LEN=$3
fi
for g in `groups $USER |sed s'/ /\n/g' |egrep '^g'`;do
	groupdel $g
done
# create groups and folders
for i in `seq -f "%0${LEN}g" 1 $NUM`; do
	g=g$i	
	[ `egrep -c "^$g" /etc/group` -eq 0 ] || groupdel $g
	groupadd -g 1$i $g
	usermod -a -G $g $USER	
	[ -d $g ] || mkdir $g
	chgrp $g $g
	chmod 070 $g
done
groups $USER

