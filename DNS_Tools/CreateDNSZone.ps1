$zone = [wmiclass]"\\csdc1\root\MicrosoftDNS:MicrosoftDNS_Zone"
$zone.CreateZone("DEVLab.com",0,$true)                              # <-- forward zone
$zone.CreateZone("175.168.192.in-addr.arpa",0,$true)                # <-- reverse zone

# view zone configuration 
# zone list
get-wmiobject -computername 'DC01' -NameSpace 'root\MicrosoftDNS' -class MicrosoftDNS:MicrosoftDNS_Zone | Select-Object Name
