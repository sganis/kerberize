#!/bin/bash
#
# 16k * 128k = 2.1GB
[ $# -eq 1 ] || {
	echo "Usage: $0 [remote folder]"; exit
}
DEST=$1
#temp=`mktemp`
#FILE=`basename $temp`
FILE=testfile.XXXX
echo "Copying /dev/zero -> $DEST/$FILE"
time dd if=/dev/zero of=$DEST/$FILE bs=16k count=128k

echo "Copying $DEST/$FILE -> /dev/null"
time dd if=$DEST/$FILE of=/dev/null bs=16k

rm -r $DEST/$FILE
echo Done.
echo
