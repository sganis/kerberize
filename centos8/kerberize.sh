#!/bin/sh
#######################################################################
# Script to kerberize Linux
# flask web app without joining to domain
# Tested in CentOS 8 with Windows 2022
#
# Author: San (sganis@gmail.com)
# Date: 08 June 2023
#
# Requirements:
# - AD DNS with forward and reversed DNS resolution for linux host
# - linux hostname must resolve to fqdn: centos.example.com
# - create windows account, password never expires
# - windows account, delegation, trust this user for delagation to any service (kerberos only)
# - create keytab and transfer to linux
# - firewall ports

dnf install -y gcc gcc-c++ sssd krb5-workstation bind-utils nmap python38 python38-devel chrony


# colorize
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NORMAL=`tput sgr0`
COLS=61 

function to_upper()
{
        echo $1 |tr '[a-z]' '[A-Z]'
}
function test_port()
{
	nmap -Pn -n -p$1 $2 |grep "$1/tcp open"|wc -l
}
function test_udp_port()
{
	nmap -sU -p$1 $2 |grep "$1/udp open"|wc -l
}
function report()
{
	msglen=$1
	result=$2
	space=$[COLS-msglen] 
	if [ $result -eq 1 ];then
	printf '%*s%s%s%s%s\n' $space "[ " "$GREEN" "Ok" "$NORMAL" " ]"
	else
	printf '%*s%s%s%s%s\n' $space "[ " "$RED" "Fail" "$NORMAL" " ]"
	fi
}	

HOST=`hostname -s`
DOMAIN=`hostname -d`
HOSTFQDN=`hostname -f`
NTDOMAIN=`echo $DOMAIN |awk -F. '{print $1}'`
TLD=`echo $DOMAIN|awk -F. '{print $2}'`
HOSTUP=`to_upper $HOST`
REALM=`to_upper $DOMAIN`
WORKGROUP=`to_upper $NTDOMAIN`
# requires bind-utils
DC=`dig any _kerberos._tcp.$DOMAIN +short |awk '{print $4}'|awk -F. '{print $1}'`
DCFQDN="$DC.$DOMAIN"
DCFQDNUP=`to_upper $DCFQDN`
#DCIP=`dig _SRV example.com +short`
LDAP_BASE="dc=$NTDOMAIN,dc=$TLD"
LDAP_USERS="cn=users,$LDAP_BASE"
LDAP_GROUPS=$LDAP_USERS

# end modifications here *****************************************
echo
echo "Check before making changes:"
echo "HOST:      $HOST"
echo "HOSTUP:    $HOSTUP"
echo "HOSTFQDN:  $HOSTFQDN"
echo "DOMAIN:    $DOMAIN"
echo "DC:        $DC"
echo "DCFQDN:    $DCFQDN"
echo "WORKGROUP: $WORKGROUP"
echo "REALM:     $REALM"
echo
echo -n "Are all variables correct? (y/N): "
read A
echo Your answer: $A
case $A in
    [Yy]) ;;
       *) exit ;;
esac

# testing network services and configuration
i=0
msg="Testing DNS..."
echo -n $msg
res=`test_port 53 $DC`
report ${#msg} $res 
i=$[i+res]
msg="Testing NTP..."
echo -n $msg
res=`test_udp_port 123 $DC` 
report ${#msg} $res
i=$[i+res]
msg="Testing KDC..."
echo -n $msg
res=`test_port 88 $DC`
report ${#msg} $res
i=$[i+res]
msg="Testing Kerberos Password Service..."
echo -n $msg
res=`test_port 464 $DC`
report ${#msg} $res
i=$[i+res]
msg="Testing Netbios over IP..."
echo -n $msg
res=`test_port 445 $DC`
report ${#msg} $res
i=$[i+res]
msg="Testing Ldap..."
echo -n $msg
res=`test_port 389 $DC`
report ${#msg} $res
i=$[i+res]

echo "Initial tests: $i/6"

if [ ! $i -eq 6 ];then
	echo -n "Some tests failed. Continue? (y/N): "
	read A
	case $A in
		[Yy]) ;;
		   *) exit ;;
	esac
fi

# leave domain
#realm leave $DOMAIN
#rm -f /var/lib/sss/db/*
#systemctl stop   sssd.service
#systemctl start  sssd.service
echo "Cleanup..."
kdestroy

# time sync
echo "Synchronizing time..."
systemctl start chronyd
systemctl enable chronyd
F=/etc/chrony.conf
mv -f --backup=numbered $F $F.orig
cp -v etc-chrony.conf $F
sed -i "s/DC.EXAMPLE.COM/$DCFQDN/" $F
timedatectl set-ntp true
systemctl restart chronyd
chronyc sources

# setup kerberos
echo "Configuring kerberos..."
F=/etc/krb5.conf
mv -f --backup=numbered $F $F.orig 
cp -v etc-krb5.conf $F
sed -i "s/EXAMPLE.COM/$REALM/" $F
sed -i "s/dc.example.com/$DCFQDN/" $F
sed -i "s/example.com/$DOMAIN/" $F
chmod 644 $F

# # setup samba
# echo "Configuring samba..."
# F=/etc/samba/smb.conf
# mv -f --backup=numbered $F $F.orig
# cp -v etc-samba-smb.conf $F
# sed -i "s/workgroup = EXAMPLE/workgroup = $WORKGROUP/" $F
# sed -i "s/HOST/$HOSTUP/" $F
# sed -i "s/realm = EXAMPLE.COM/realm = $REALM/" $F
# sed -i "s/password server = DC.EXAMPLE.COM/password server = $DCFQDNUP/" $F
# chmod 644 $F

# check local keytab for new entry
#klist -k
#msg="Testing kerberos credentials for $HOSTUP\$..."
#echo -n $msg
#report ${#msg} $[`kinit -k $HOSTUP$|wc -l`+1]
# chmod 644 /etc/krb5.keytab


# echo "Configuring sssd..."
# F=/etc/sssd/sssd.conf
# mv -f --backup=numbered $F $F.orig
# cp -v etc-sssd-sssd.conf $F
# sed -i "s/domains = example.com/domains = $DOMAIN/" $F
# sed -i "s/\[domain\/example.com\]/\[domain\/$DOMAIN\]/" $F
# sed -i "s/ad_domain = example.com/ad_domain = $DOMAIN/" $F
# sed -i "s/krb5_realm = EXAMPLE.COM/krb5_realm = $REALM/" $F
# chmod 600 $F
# systemctl enable sssd.service
# systemctl stop   sssd.service
# systemctl start  sssd.service
# authconfig --update --enablesssd --enablesssdauth --enablemkhomedir --nostart
# systemctl enable oddjobd.service
# systemctl start oddjobd.service

# ssh
# mv -f --backup=numbered /etc/ssh/ssh_config /etc/ssh/ssh_config.orig
# mv -f --backup=numbered /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
# cp -v etc-ssh-ssh_config /etc/ssh/ssh_config
# cp -v etc-ssh-sshd_config /etc/ssh/sshd_config
# chmod 644 /etc/ssh/ssh_config
# chmod 600 /etc/ssh/sshd_config

# To test ssh, su administrator, kinit, and ssh another machine.
# It must login without asking password, the authentication method
# gssapi-with-mic must be tried first, it not, change it with
# -o in command line:
# ssh -o PreferredAuthentications=gssapi-with-mic -v hostname
# If sshd is asking for password, then /var/log/secure logs,
# common errors:
# - Wrong principal in request: the ssh client is offering a ticket with wrong host,
# clear cache with kdestroy, kinit, and ssh again. If you are using putty,
# clear cache locking the desktop, and enter password again with contrl+alt+del,
# or with the windows klist.exe tool, using the  purge option: klist purge.
# - Wrong key table: delete the host from AD, realm leave domain, 
# rm /var/lib/sss/db/*, realm join domain, restart sshd and sssd.
# Test login in with putty from windows, use putty 0.64,
# the only configuration is Connection/Data/Use system username checked.
# If you want deletagion, set Connection/SSH/Auth/GSSAPI delegation, and set
# "Trust this computer for delegation to any service (Kerberos only)" 
# under the "Delegation" tab in Users and Computers mmc in AD.
# Important: keep your usernames lowercase, Administrator in windows maps to
# administrator in linux, and delegation will not work: the ticket created
# for the windows user has the principal Administrator@REALM, and linux
# expect administrator@REALM, so sshd will ask for pasword again.

# restart ssh
systemctl enable sshd.service
systemctl stop   sshd.service
systemctl start  sshd.service

# restart sss
#systemctl enable sssd.service
#systemctl stop   sssd.service
#systemctl start  sssd.service

# test
# msg="Testing if $HOST is joined to domain..."
# echo -n $msg
# report ${#msg} `net ads testjoin |grep 'Join is OK' |wc -l`
# msg="Testing ldap queries..."
# echo -n $msg
# report ${#msg} `ldapsearch -H ldap://$DCFQDN -Y GSSAPI -N -b $LDAP_BASE "(&(objectClass=computer)(dNSHostName=$HOSTFQDN))" 2>/dev/null |grep numEntries |wc -l`
echo "stopping firewall..."
systemctl stop firewalld

echo Done.
echo




