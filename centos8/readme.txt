# Windows 2012 essentials tips

# Disable password complexity
# Search Apps for “gpmc.msc”, Group Policy Management -> Forest: YourServerName.local -> # Domains, Select “Default Domain Policy” then right-click and select “Edit…” 
# Computer Configuration -> Windows Settings -> Security Settings -> Account Policies -> # Password Policy, disable all, or set 0 to all.

# Disable the screen lock
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\
# 7516b95f- f776-4464-8c53-06167f40cc99\8EC4B3A5-6868-48c2-BE75-4F3044BE88A7 
# in the right side of console change that value “Attributes=2”, then
# Control Panel > Power Options > Change Plan Settings > 
# Change Advanced Power Settings > Display section “Console lock display off timeout” 
# is now available, set it to 0.

# Set property "trust this computer for delegatioin to any service (kerberos only)"
# this is required for ticket delegations (forward)
# get-adcomputer -filter * | set-adcomputer -TrustedForDelegation 1

# To renew a kerberos ticket in windows, you need to lock, 
# cntrl-alt-del and password again, 
# or use the command klist.exe -purge