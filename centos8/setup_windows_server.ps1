# Powershell script to configure a Windows 2012 domain controller
# disable execution policy, run this before this script
# Set-ExecutionPolicy ByPass

# create groups
$user = "user2"
$list = 1..50

ForEach($i in $list) 
{
	$group = "g" + $i.ToString("00")
	$group
	new-adgroup $group -GroupScope Global
	add-adgroupmember -identity $group -members $user
}

# Windows 2012 essentials tips

# Identity Management for Unix

# Install admin tools:
# Dism.exe /online /enable-feature /featurename:adminui /all 

# Install Server for NIS
# Dism.exe /online /enable-feature /featurename:nis /all 

# Set the Administrator account to login as lower case administrator@domain
# in user properties -> account
# Configure putty to use the system username in connection -> data
# and GSSAPI deletagion in connection -> ssh -> auth -> gssapi
# If putty is asking passowrd, lock and force a ticket renewal entering the password again

# To disable password complexity:
# Search Apps for “gpmc.msc”, Group Policy Management -> Forest: YourServerName.local -> # Domains, Select “Default Domain Policy” then right-click and select “Edit…” 
# Computer Configuration -> Windows Settings -> Security Settings -> Account Policies -> # Password Policy, disable all, or set 0 to all.

# Allow users to login locally to a domain controller,
# GroupPolicyObjectName [DomainControllerName] Policy / 
# Computer Configuration/Windows Settings/Security Settings/Local Policies / 
# User Rights Assignment
# refresh gpo with gpupdate /force

# To disable the screen lock:
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\
# 7516b95f- f776-4464-8c53-06167f40cc99\8EC4B3A5-6868-48c2-BE75-4F3044BE88A7 
# in the right side of console change that value “Attributes=2”, then
# Control Panel > Power Options > Change Plan Settings > 
# Change Advanced Power Settings > Display section “Console lock display off timeout” 
# is now available, set it to 0.

# Auto login
# HKLM\Software\Microsoft\Windows NT\CurrentVersion\winlogon
# AutoAdminLogon = "1"
# DefaultUserName = Your user name
# DefaultPassword = Your password

# Set computer property "trust this computer for delegatioin to any service (kerberos only)"
# this is required for ticket delegations (forward)
# using powershell
# get-adcomputer -filter * | set-adcomputer -TrustedForDelegation 1

# To renew a kerberos ticket in windows, you need to lock, 
# cntrl-alt-del and password again, 
# or use the command klist.exe -purge

# Check principals with setspn $host after joining the linux machine.
reg
