#sets unix attribues and creates a group based on the last attribute avalible

Param(
  [Parameter(Position=0,mandatory=$true)]
  [string]$username
)

# RFC2307 attributes for groups:
# - msSFU30NisDomain
# - gidNumber
# and for users:
# - uidNumber
# - gidNumber
# - unixHomeDirectory
# - loginShell
# - msSFU30NisDomain
# examples:
# New-ADGroup -name linux_user -GroupScope 1 -OtherAttributes @{msSFU30NisDomain='emc';gidNumber=20000}
# Set-ADGroup -Instance linux_user -Add @{msSFU30NisDomain='emc';gidNumber=20000}
# New-ADUser -name user1 -OtherAttributes @{uidNumber=(10000+$i);gidNumber=20000;unixHomeDirectory=('/home/EMC/user'+$i);loginShell='/bin/bash';msSFU30NisDomain='emc'}
# Set-ADUser -Instance user1 -Add @{uidNumber=(10000+$i);gidNumber=20000;unixHomeDirectory=('/home/EMC/user'+$i);loginShell='/bin/bash';msSFU30NisDomain='emc'}
# for ($i=1; $i -le 5; $i++){New-ADUser -name ('user' + $i) -PasswordNeverExpires:$true -AccountPassword (ConvertTo-SecureString "Passw0rd" -AsPlainText -Force) -Enabled:$true -OtherAttributes @{uidNumber=(10000+$i);gidNumber=20000;unixHomeDirectory=('/home/EMC/user'+$i);loginShell='/bin/bash';msSFU30NisDomain='emc'}; Add-ADGroupMember -Identity linux_user -Members ('user'+$i)}

$linux_users_gid = 10000
$list = 1..50
$domain = "test"
$homedir = "/home/" + "$username"

Function NextUid {
  #gets the next avalible gid number to assign to the object
  #$gidnum = Get-ADObject -SearchBase "OU=UnixGroups,DC=Contoso,DC=LOCAL" -filter {gidnumber -like "*"}  -Properties * | 
  $uidnum = Get-ADObject -filter {uidnumber -like "*"}  -Properties * | 
    select -ExpandProperty uidnumber |
    sort uidnumber
  $next = $uidnum |Measure -Maximum |select -ExpandProperty maximum 
  $next++
  $next 
}

Function NextGid {
  #gets the next avalible gid number to assign to the object
  $gidnum = Get-ADObject -filter {gidnumber -like "*"}  -Properties * | 
    select -ExpandProperty gidnumber |
    sort gidnumber
  $next =$gidnum |Measure -Maximum |select -ExpandProperty maximum
  $next++
  $next 
}

Function Check-group ($groupname) {
  get-adgroup -Identity $groupname
}

# Function Check-user-has-uid ($username) {
#   get-aduser -Identity $username -Properties * |select -ExpandProperty uidNumber
# }

# Function Check-group-has-gid ($groupname) {
#   get-adgroup -Identity $groupname -Properties * |select -ExpandProperty gidNumber
# }


# set unix attributes in user if needed
$uid = get-aduser -Identity $username -Properties * |select -ExpandProperty uidNumber
if ($uid -ne $null) {
  Write-Output "$username has UID #$uid"
} else {
  Set-ADUser -Identity $username -Add @{msSFU30NisDomain = "$domain"}
  Set-ADUser -Identity $username -Add @{loginShell = '/bin/bash'}
  Set-ADUser -Identity $username -Add @{homeDirectory = "$homedir"}
  Set-ADUser -Identity $username -Add @{uidNumber = NextUid}
  Set-ADUser -Identity $username -Add @{gidNumber = "$linux_users_gid"}
  Write-Output "Unix attributes added to $username"
}

# add user to windows group linux_users
Add-ADGroupMember -identity "linux_users" -members $username
Write-Output "$username added to linux_users group"
# create groups and add user to those groups
ForEach($i in $list) {
  $groupname = "g" + $i.ToString("00")
  $groupname
  # create group if needed
  $group = Check-group($groupname)
  # $group = get-adgroup -Identity $groupname
  $group
  if ($group -eq $null) {
    New-ADGroup -Name $groupname -GroupScope Global
    Write-Output "New group $groupname created"
    
  } else {
    Write-Output "Group $groupname already exists"
  }
  # add unix attributes
  $gid = get-adgroup -Identity $groupname -Properties * |select -ExpandProperty gidNumber
  if ($gid -eq $null) {
    # get next GID
    $nextgid = NextGid
    Set-ADGroup -Identity $groupname -Add @{gidNumber = "$nextgid"}
    Set-ADGroup -Identity $groupname -Add @{msSFU30NisDomain = "$domain"}
    Write-Output "Unix attributes added to $groupname"
  } else {
    Write-Output "$groupname already has a GID #$gid"
  }
  # add user to this windows group
  Add-ADGroupMember -identity $groupname -members $username  
  Write-Output "$username added to windows $groupname"
  # add user to unix group
  $group_dn = "CN=$groupname,CN=Users,DC=test,DC=com"
  $group_dn
  $user_dn = "CN=$username,CN=Users,DC=test,DC=com"
  $user_dn
  Get-ADObject $group_dn | Set-ADObject -Add @{msSFU30PosixMember="$user_dn";memberUid="$username"}
  Write-Output "$username added to unix $groupname"
}



