#!/bin/sh

if [ $# -lt 1 ];then
	echo "usage: $0 num_of_dirs [zerofill=2]"; exit
fi
LEN=2
if [ $# -gt 1 ];then
        LEN=$2
fi

for i in `seq -f "%0${LEN}g" 1 $1`
do 
	ls g$i
done

