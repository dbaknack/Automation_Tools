$response.close()

# login and address
$username    = ''
$ftp         = ''
$subfolder   = ''

# create the ftp request
$ftpuri                 = $ftp + $subfolder
$uri                    = [system.URI] $ftpuri
$ftprequest             = [system.net.ftpwebrequest]::Create($uri)
$ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,"anonymous@localhost")
$ftprequest.EnableSsl   = $true
$ftprequest.Method      = [system.net.WebRequestMethods+ftp]::ListDirectoryDetails


# get a response from the FTP service
$response = $ftprequest.GetResponse()
$stream   = $response.GetResponseStream()
$reader   = New-Object System.IO.StreamReader($stream,'UTF-8')

$ftpObj      = @()
$regex_mask  = "^(\S+)\s+(\S+)\s+(\d+)\s+(\S+)"
$regex_mask2 = "^(.*)_(.*)_(.*)_(.*)_.*(\d).*"

# go line by line on the request
do{

    $line        = $reader.ReadLine()
    $endofstream = $reader.EndOfStream

 $endofstream
 $line
 read-host 'stream status'
    if($line  -ne $null){
        $date        = ($line) -replace $regex_mask,'$1'
        $time        = ($line) -replace $regex_mask,'$2'
        $size        = ($line) -replace $regex_mask,'$3'
        $filename    = ($line) -replace $regex_mask,'$4'

        $ftp_fileprop = [ordered]@{
            datetime = [datetime]::parseexact(("$date $time"),'MM-dd-yy hh:mmtt',$null).ToString('yyyy-MM-dd HH:mm.ss')
            size     = [double]$size
            name     = [string]$filename
            instance = $filename -replace "$regex_mask2",'$1'
            database = $filename -replace "$regex_mask2",'$3'
        }

        $ftpObj += new-object psobject -Property $ftp_fileprop
    }else{
        Write-Verbose "Stream complete" -Verbose
    }
}until($endofStream -eq $true)


# download by group of backups
$instancegrp = $ftpObj | Group-Object -Property instance -AsHashTable

foreach($instance in $instancegrp.Keys){
    # access group by instance and group by database
        $databasegrp = $instancegrp[$instance] | Group-Object -Property database -AsHashTable

        foreach($database in $databasegrp.keys){
            foreach($backupfile in $databasegrp[$database]){
                $backupfile.size
            }


        }

}

$objGrp[1]

$ftpObj.name -replace "$regex_mask2",'$1' | Sort-Object -Unique
$ftpObj.name[0] -match $regex_mask2
$ftpObj.name -replace "$regex_mask2",'$3'
$ftpObj.name -replace "$regex_mask2",'$5'

$instance = $ftp_fileprop.name -replace "^(.*)_(.*)_(.*)_(.*)_(.*)",'$1'
$database = $ftp_fileprop.name -replace "^(.*)_(.*)_(.*)_(.*)_.*(\d).*",'$2'
$baknum   = $ftp_fileprop.name -replace "^(.*)_(.*)_(.*)_(.*)_.*(\d).*",'$5'

$instance
$database
$baknum
