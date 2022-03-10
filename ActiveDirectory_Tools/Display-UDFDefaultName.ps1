<#
 when using pw to create a user account, i can't control the format of the display name.
 the GUI tool defaults to displaying the name as first name followed by last name.

this names browsing more difficult since first names tend not to as selective as last names.
task: modify the way display names are created when using the GUI tools. change default behavior
#>

$rootDSE    = [ADSI]"LDAP://RootDSE"
$dispspec   = [ADSI] ("LDAP://cn=User-Display,cn=409,cn=DisplaySpecifiers," + $rootDSE.ConfigurationNamingContext)
$dispspec.CreateDialog = "%<sn> %<givenName>"
$dispspec.SetInfo()

$disp = [ADSI]("LDAP://,cn=409,cn=DisplaySpecifiers," + rootDSE.ConfigurationNamingContext)
$disp.children

Get-ADObject  `
        -Identity "cn=User-Display,cn=409,cn=DisplaySpecifiers, `
        $((Get-ADRootDSE).configurationNamingContext)" `
        -Properties CreateDialog |
        Format-List *
        Set-ADObject `
        -Identity "cn=User-Display,cn=409,cn=DisplaySpecifiers,`
        $((Get-ADRootDSE).configurationNamingContext)"  `
        -Replace @{CreateDialog = "%<sn> %<givenName>"}