#!/bin/sh
#***********************************************************
# Script to join a Linux machine to AD
# Tested in CentOS 6.3 with Windows 2008 R2 with IMU
# It also kerberizes SSH 
#
# Author: Santiago Ganis (sganis@gmail.com)
# Date: 08 Nov 2012 
#
# works only in hostnames like host.domain.tld
# you might need to modify HOST, DOMAIN, and other variables
# 
#***********************************************************

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
function report()
{
	msglen=$1
	result=$2
	space=$[COLS-msglen] 
	if [ $result -eq 1 ];then
	printf '%*s%s%s%s%s\n' $space "[ " "$GREEN" "Pass" "$NORMAL" " ]"
	else
	printf '%*s%s%s%s%s\n' $space "[ " "$RED" "Fail" "$NORMAL" " ]"
	fi
}	

# required packages:
# sssd 			: sssd service
# samba-common 		: net command to join machine
# krb5-workstation	: kerberos client components 
# openldap-clients 	: ldap components
# ntp			: time sync
# optional:
# bind-utils		: dns utilities, dig,nslookup
# nmap   		: port scan utility

# install testing tools
yum install -y bind-utils nmap

# check this variables and modify if needed
# start modifications here ****************************************
ADMIN=""
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
res=`test_port 123 $DC` 
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

# install packages
yum install -y openssh sssd samba-common krb5-workstation \
        openldap-clients ntp

F=/etc/krb5.conf
mv -f --backup=numbered $F $F.orig 
cp -v krb5.conf $F
sed -i "s/default_realm = EXAMPLE.COM/default_realm = $REALM/" $F
sed -i "s/EXAMPLE.COM = {/$REALM = {/" $F
sed -i "s/kdc = dc1.example.com:88/kdc = $DCFQDN/"  $F
sed -i "s/admin_server = dc1.example.com:464/admin_server = $DCFQDN/" $F
sed -i "s/default_domain = example.com/default_domain = $DOMAIN/"  $F
sed -i "s/.example.com = EXAMPLE.COM/.example.com = $REALM/"  $F
sed -i "s/example.com = EXAMPLE.COM/example.com = $REALM/"  $F

F=/etc/samba/smb.conf
mv -f --backup=numbered $F $F.orig
cp -v smb.conf $F
sed -i "s/workgroup = EXAMPLE/workgroup = $WORKGROUP/" $F
sed -i "s/netbios name = BOX2/netbios name = $HOSTUP/" $F
sed -i "s/realm = example.com/realm = $DOMAIN/" $F

F=/etc/sssd/sssd.conf
mv -f --backup=numbered $F $F.orig
cat > $F <<EOF
[sssd]
config_file_version = 2
domains = $DOMAIN
debug_level = 2
reconnection_retries = 3
sbus_timeout = 30
services = nss, pam
[nss]
filter_groups = root
filter_users = root
reconnection_retries = 3
entry_cache_nowait_percentage = 75
[pam]
reconnection_retries = 3
[domain/$DOMAIN]
debug_level = 3
ldap_uri = ldap://$DCFQDN
ldap_sasl_authid = $HOSTUP\$@$REALM
ldap_user_search_base = $LDAP_USERS
ldap_group_search_base = $LDAP_GROUPS
krb5_realm = $REALM
krb5_server = $DCFQDN
min_id = 10000
max_id = 30000
cache_credentials = true
ldap_purge_cache_timeout = 1 # disable
enumerate = false
id_provider = ldap
krb5_validate = true
auth_provider = krb5
ldap_schema = rfc2307bis
ldap_user_object_class = person
ldap_user_modify_timestamp = whenChanged
ldap_user_home_directory = unixHomeDirectory
ldap_user_shell = loginShell
ldap_user_principal = userPrincipalName
ldap_user_name = sAMAccountName
ldap_user_uid_number = uidNumber
ldap_user_gid_number = gidNumber
ldap_group_object_class = group
ldap_group_modify_timestamp = whenChanged
ldap_group_nesting_level = 5
ldap_group_name = sAMAccountName
ldap_group_gid_number = gidNumber
ldap_account_expire_policy = ad
ldap_krb5_keytab = /etc/krb5.keytab
ldap_krb5_init_creds = true
ldap_pwd_policy = mit_kerberos
chpass_provider = krb5
ldap_sasl_mech = GSSAPI
ldap_force_upper_case_realm = true
EOF

chmod 600 $F
mv -f --backup=numbered /etc/pam.d/system-auth /etc/pam.d/system-auth.orig
mv -f --backup=numbered /etc/nsswitch.conf /etc/nsswitch.conf.orig
mv -f --backup=numbered /etc/ssh/ssh_config /etc/ssh/ssh_config.orig
mv -f --backup=numbered /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
cp -v system-auth /etc/pam.d/system-auth
cp -v nsswitch.conf /etc/nsswitch.conf
cp -v ssh_config /etc/ssh/ssh_config
cp -v sshd_config /etc/ssh/sshd_config

# time sync
[ `ps aux|grep -v grep |grep 'ntpd'|wc -l` -eq 0 ] || service ntpd stop
ntpdate $DCFQDN
service ntpd start

# setup DNS
# setup hostname with FQDN
#/etc/hosts
# $IP $HOSTFQDN $HOST
#/etc/sysconfig/network
#HOST=$HOSTFQDN
# enable unsecure update in AD DNS
# sync time


# verify kerberos client is installed
#yum list installed | grep krb5

# get ticket
kdestroy
#kinit administrator
#klist

# join linux machine to AD
if [ -z "$ADMIN" ];then
	echo -n "Admin user to join machine to domain:"
	read ADMIN
fi
net ads join createcomputer=computers -U $ADMIN 

#net -U administrator join createupn=host/$HOSTFQDN@$REALM createcomputer=computers 
# check a new computer in AD
# check local keytab for new entry
klist -k
msg="Testing kerberos credentials for $HOSTUP\$..."
echo -n $msg
report ${#msg} $[`kinit -k $HOSTUP$|wc -l`+1]

# check ticket for machine
#klist

# configure authentication
#system-config-authentication

# create a keytab file to avoid password prompt
#> ktutil
#  ktutil:  addent -password -p username@EXAMPLE.COM -k 1 -e rc4-hmac
#  ktutil:  addent -password -p username@EXAMPLE.COM -k 1 -e aes256-cts
#  ktutil:  wkt username.keytab
#  ktutil:  quit 


# in windows DC, generate keytab for host to query ldap if not anonymous
#c:\>setspn -A host/centos.example.com@EXAMPLE.COM centos
#c:\>setspn -L centos
#c:\>ktpass /princ host/centos.example.com@EXAMPLE.COM /out centos.keytab /crypto all /ptype KRB5_NT_PRINCIPAL ­desonly /mapuser EXAMPLE\centos$ +rndPass
# copy centos.keytab to linux box

# verify ldap queries
#kinit -k -t sant.keytab -p sant@EXAMPLE.COM;ldapsearch -H ldap://dc1.example.com -Y GSSAPI -N -b DC=example,dc=com "(&(objectClass=user)(sAMAccountName=sant))"
#kinit -k -t centos.keytab -p host/centos.example.com@EXAMPLE.COM;ldapsearch -H ldap://dc1.example.com -Y GSSAPI -N -b DC=example,dc=com "(&(objectClass=user)(sAMAccountName=ganissa))"


chkconfig sshd on
chkconfig ntpd on
chkconfig sssd on
# stop if running
[ `ps aux|grep -v grep |grep '/sbin/sssd'|wc -l` -eq 0 ] || service sssd stop
[ `ps aux|grep -v grep |grep '/sbin/sshd'|wc -l` -eq 0 ] || service sshd stop
service sssd start
service sshd start

# test
msg="Testing if $HOST is joined to domain..."
echo -n $msg
report ${#msg} `net ads testjoin |grep 'Join is OK' |wc -l`
msg="Testing ldap queries..."
echo -n $msg
report ${#msg} `ldapsearch -H ldap://$DCFQDN -Y GSSAPI -N -b $LDAP_BASE "(&(objectClass=computer)(dNSHostName=$HOSTFQDN))" 2>/dev/null |grep numEntries |wc -l`

echo Done.
echo



