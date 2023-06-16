#!/bin/sh
######################################################################
#
# Example CGI script that uses Kerberos credentials cached by
# mod_auth_kerb compiled with caching option.
#
# Submitted by: Von Welch <vwelch@ncsa.uiuc.edu>
#
# mod_auth_kerb - Daniel Henninger <daniel@ncsu.edu>
#
######################################################################

# PATH=/usr/heimdal/bin:$PATH

# Output HTML header
echo Content-type: text/plain
echo

echo "The time is: `date`"
echo

# $REMOTE_USER should be set by httpd
if [ -z "$REMOTE_USER" ]; then
	echo '$REMOTE_USER not set.'
	exit 1
fi

echo "REMOTE_USER is $REMOTE_USER"
echo

if [ -z "$KRB5CCNAME" ]; then
	echo 'Kerberos credential cache name $KRB5CCNAME does not exist.'
	echo "Check the this server is trusted for delegation in AD."
	exit 1
fi

# Do Kerberos stuff

klist
echo

username=`echo $REMOTE_USER|awk -F"@" '{print $1}'`
#echo "username: $username"
echo "user groups:"
groups $username
echo
exit 0