$UDFunctions = [ordered]@{}
$UDFunctions.'Get-UDFDriveStats'  += @{
    BlockName   = 'Get-UDFDriveStats'
    Description = "
        Returns hostname, drivename, label, total space, free space, used space, free space in percent.
    "
    ExecCmd     = {&($UDFunctions.'Get-UDFDriveStats').Scriptblock.command -Filter $Filter -labels $Labels}
    ScriptBlock = @{
        Command         = {
    #[CmdletBinding(DefaultParameterSetName = 'Filter')]
    param(
        [Parameter(Position = 0,Mandatory = $true)]
        [validatenotnullorempty()]
        [validateset('Include','Exclude')]
        [string]$Filter,

        [Parameter(Position = 1,Mandatory = $false)]
        [string[]]$Labels
    )
    begin{
        $totalgb   = @{name = "capacity_gb";  expression = {[math]::round(($_.capacity/1073741824),2)}}
        $freegb    = @{name = "freespace_gb"; expression = {[math]::round(($_.freespace / 1073741824),2)}}
        $usedspace = @{name = "usedspace_gb"; expression = {[math]::round((($_.capacity - $_.freespace) / 1073741824),2)}}
        $freeperc  = @{name = "free_Per";       expression = {[math]::round(((($_.freespace / 1073741824)/($_.capacity / 1073741824)) * 100),0)}}
        $volumes   = @()
    }
    process{
        if($filter -like 'Include'){
            foreach($label in $Labels){
                $volumes += get-wmiobject win32_volume  |
                select-object systemname, name, label, $totalgb,$freegb,$usedspace,$freeperc |
                Where-Object {$_.label -like $label}
            }
            $volumes
        }elseif($filter -like 'Exclude'){
            $compare = @()
            $volumes = get-wmiobject win32_volume  | select-object systemname, name, label, $totalgb,$freegb,$usedspace,$freeperc
            foreach($Label in $Labels){
                $compare += $volumes | Where-Object {$_.label -like $label}
            }
            $volumes | Select-Object * | where {$_.label -notin $compare.label}
        }
    }
    end{
        $volumes = $null
        $compare = $null
    }
}
        LocalCmd        = {
            $totalgb   = @{name = "capacity_gb";  expression = {[math]::round(($_.capacity/1073741824),2)}}
            $freegb    = @{name = "freespace_gb"; expression = {[math]::round(($_.freespace / 1073741824),2)}}
            $usedspace = @{name = "usedspace_gb"; expression = {[math]::round((($_.capacity - $_.freespace) / 1073741824),2)}}
            $freeperc  = @{name = "free_Per";       expression = {[math]::round(((($_.freespace / 1073741824)/($_.capacity / 1073741824)) * 100),0)}}
            $volumes = get-wmiobject win32_volume
            $volumeresults = $volumes  | select-object systemname, name, label, $totalgb,$freegb,$usedspace,$freeperc;
            $volumeresults}
        TimeoutProperty = 10
    }
}
$UDFunctions.'Get-UDFHostNames'   += @{
    BlockName   = 'Get-UDFHostNames'
    ExecCmd     = {&($UDFunctions.'Get-UDFHostNames').Scriptblock.command -HostName $HostNameFilter}
    ScriptBlock = @{
        Command         = {
    param(
        [Parameter(Position = 0,Mandatory = $true)]
        [string]$HostName
    )
    begin{
        $objectclass       = "computer"
        $root              = [adsi]''
        $search            = new-object system.directoryservices.directorysearcher($root)     
        $blockName         = 'Get-UDFHostNames'
        $expression        = @{name = "HostNames";  expression = {[string]($_).toupper()}}
    }
    process{
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $search.filter = "(&(objectclass=$objectclass)(cn=$HostName))"
        try{
            [array]$hostreturned  = ($search.findall()).properties.name
        }catch{
            $Error[0]
            $elapsedTime = $timer.ElapsedMilliseconds
            $timer.stop()
            return
        }
    }
    end{
        $timer.stop()
        $elapsedTime = $timer.ElapsedMilliseconds
        $item = @{
            ElapsedTime_Milliseconds = $elapsedTime
            HostNames  = $hostreturned
            BlockName  = $blockName
            Size_Bytes  =  [system.text.Encoding]::UTF8.GetByteCount($hostreturned)
        }
        $item
    }
}
        TimeoutProperty = 10
    }
}
$UDFunctions.'Test-UDFConnection' += @{
    BlockName   = 'Test-UDFConnection'
    ExecCmd     = {start-job -Name $_ -ScriptBlock $UDFunctions.'Test-UDFConnection'.ScriptBlock.Command -ArgumentList $_}
    ScriptBlock = @{
        Command         = {
    param(
        [Parameter(Position = 0,Mandatory = $false)]
        [string]$HostName = 'localhost',
        $blockName = 'Test-UDFConnection'
    )
    Process{
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        if($HostName -notmatch [environment]::MachineName){  
            if(test-connection -ComputerName $HostName -count 3 -ErrorAction SilentlyContinue){
                [string]$ping = $true
                [string]$prop = $HostName
            }else{
                [string]$ping = $false
                [string]$prop = $HostName            
            }
        }else{
            [string]$ping = $true
            [string]$prop = 'Localhost'
        }


    }
    end{
        $timer.stop()
        $elapsedTime = $timer.ElapsedMilliseconds
        $status = @{
            ElapsedTime_Milliseconds = $elapsedTime
            hostname      = $HostName
            ping_status   = $ping
            BlockName  = $blockName
            Size_Bytes  =  [system.text.Encoding]::UTF8.GetByteCount($HostName)
            sessionobject = $prop
        }
        [pscustomobject]$status
    }
}
        TimeoutProperty = 10
    }
}

$HostNameFilter = ''
$results        = start-job -ScriptBlock $UDFunctions['get-udfhostnames'].ScriptBlock.Command -ArgumentList $HostNameFilter
$results

$results.HostNames | foreach{&($UDFunctions.'Test-UDFConnection'.ExecCmd) -HostName $_ }
$connectionresults = get-job | Receive-Job
Get-Job | Remove-Job

($connectionresults| Where {$_.ping_status -eq 'true'}) | ft -AutoSize
$connectionresults| Where {$_.ping_status -eq 'true'} | foreach {
    try{
        
        New-PSSession -ComputerName $_.hostname -Name "session_$($_.hostname)" -ErrorAction SilentlyContinue
        $issessions = Get-PSSession
    }catch{
       Get-PSSession | Remove-PSSession
    }
}

$filter = 'exclude'
$Labels = 'System Reserved','','Disk Witness','MSDTC','Recovery','MSTDC'
$issessions | foreach {Invoke-Command -Session $_ -ScriptBlock $UDFunctions.'Get-UDFDriveStats'.ScriptBlock.Command -ArgumentList $Filter,$Labels -AsJob}
$sessionresults = Get-Job | Receive-Job | Select-Object Systemname,Name,Label,Capacity_gb,FreeSpace_gb,UsedSpace_gb,Free_Per
$sessionresults +=  &$UDFunctions.'Get-UDFDriveStats'.ExecCmd
$sessionresults | ft -AutoSize

Get-Job | Remove-Job

$htmlhash = @{}
$htmlhash.storagereport = @()
$htmlhash.storagereport += [ordered]@{
html    = "
<html>
<style>
{0}
</style>
    <body>
<h1 class='content-heading'>
    Storage Report
</h1>
    {1}
    </body>
</html>
"
heading = '
<h1 class="content-heading">
    Storage Report
</h1>
'
style   = "
    .content-heading {
	font-family: sans-serif;
    }
    .content-table {
        border-collapse: collapse;
        margin: 25px 0;
    	margin-left:auto; 
    	margin-right:auto;
        font-size: 0.9em;
	    font-family: sans-serif;
        min-width: 400px;
        border-radius: 5px 5px 0 0;
        overflow: hidden;
        box-shadow: 0 0 20px rgba(0, 0, 0, 0.15);
    }

    .content-table thead tr {
        background-color: #009879;
        color: #ffffff;
        text-align: left;
        font-weight: bold;
    }

    .content-table th,
    .content-table td {
        padding: 12px 15px;
    }

    .content-table tbody tr {
        border-bottom: 1px solid #dddddd;
    }

    .content-table tbody tr:nth-child(even) {
        background-color: ##E0E0E0;
    }

    .content-table tbody tr:last-of-type {
        border-bottom: 2px solid #009879;
    }
"
thead   = "
<th>{0}</th>
<th>{1}</th>
<th>{2}</th>
<th>{3}</th>
<th>{4}</th>
<th>{5}</th>
<th>{6}</th>
"
tbody   = "
    <tr>
    <td>{0}</td>
    <td>{1}</td>
    <td>{2}</td>
    <td>{3}</td>
    <td>{4}</td>
    <td>{5}</td>
    <td>{6}</td>
    </tr>
"
table   = '
<table class="content-table">
<thead>
    <tr>
        {0}
    </tr>
</thead>
<tbody>
        {1}
</tbody>
</table>
'
}
 
Sort-Object -Property SystemName, label | ConvertTo-Html -Property Systemname,Name,Label,Capacity_gb,FreeSpace_gb,UsedSpace_gb,Free_%  -Head $Header | Out-file -FilePath c:\temp\psdrives.html



$sessionresults | 
Sort-Object -Property Free_Per | foreach {
 $tbody += $htmlhash.storagereport.tbody -f "$($_.systemname)","$($_.name)","$($_.label)","$($_.capacity_gb)","$($_.freespace_gb)","$($_.usedspace_gb)","$($_.free_Per)"
}

$thead = $htmlhash.storagereport.thead -f 'Systemname','Name','Label','Capacity_gb','FreeSpace_gb','UsedSpace_gb','Free_Per' 
$table = $htmlhash.storagereport.table -f "$($thead)",$($tbody)
$html =  $htmlhash.storagereport.html -f "$($htmlhash.storagereport.style)",$table 
#$html | clip.exe
$html | Out-File C:\Temp\psdrives.html
Invoke-Expression C:\Temp\psdrives.html
 Send-MailMessage -BodyAsHtml $html -Subject "PowerShell: Test Storage Report" -From '' -SmtpServer
