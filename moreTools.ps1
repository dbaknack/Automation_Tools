# ------------------------------------------------------------------------------------------------------
# Technique 1
# User creation
# PROBLEM
# We need to create a local user account on a Windows machine.

# 1) load the assembly
[void][reflection.assembly]::Load(
    "System.DirectoryServices.AccountManagement,
    Version         =   3.5.0.0,
    Culture         =   neutral,
    PublicKeyToken  =   b77a5c561934e089"
)
# 2) create the password
$password   = Read-Host "Password" -AsSecureString
$cred       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "userid", $password

# 3) set the context
$ctype      = [System.DirectoryServices.AccountManagement.ContextType]::Machine
$context    = New-Object

-TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, "pcrs2"

# 4) create the use
$usr    = New-Object -TypeName
System.DirectoryServices.AccountManagement.UserPrincipal
-ArgumentList $context

# 5) set properties
$usr.SamAccountName     = "Newuser1"
$usr.SetPassword($cred.GetNetworkCredential().Password)
$usr.DisplayName        = "New User"
$usr.Enabled            = $true
$usr.ExpirePasswordNow()

# 6) save
$usr.Save()


# create a local user account using WinNT

<#
PASSWORD WARNING I deliberately wrote this script with the password in the
script to show how obvious it is. Imagine a scenario where you create a set of new
accounts. If someone finds the password, you could have a security breach. As
an alternative, you could leave the account disabled until required.
#>
$computer       = "pcrs2"
$sam            = [ADSI]"WinNT://$computer"
$usr            = $sam.Create("User", "Newuser2")
$usr.SetPassword("Passw0rd!")
$usr.SetInfo()
$usr.Fullname   = "New User2"
$usr.SetInfo()
$usr.Description    = "New user from WinNT"
$usr.SetInfo()
$usr.PasswordExpired = 1
$usr.setInfo()
# ------------------------------------------------------------------------------------------------------
# Techinque 2 Group creation

# PROBLEM: We need to create a local group on a Windows computer.
<#
Continuing our exploration of System.DirectoryServices.AccountManagement, we
use the GroupPrincipal
#>

# Create a local group
# Load assembly
[void][reflection.assembly]::Load("System.DirectoryServices.AccountManagement,
    Version         =   3.5.0.0,
    Culture         =   neutral,
    PublicKeyToken  =   b77a5c561934e089"
)
$ctype                  = [System.DirectoryServices.AccountManagement.ContextType]::Machine

# Set context
$context                = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, "pcrs2"
$gtype                  = [System.DirectoryServices.AccountManagement.GroupScope]::Local
$grp                    = New-Object -TypeName System.DirectoryServices.AccountManagement.GroupPrincipal -ArgumentList $context, "lclgrp01"
$grp.IsSecurityGroup    = $true
$grp.GroupScope         = $gtype
$grp.Save()
