$size   = @{
    Name        =   "Capacity_Gb";
    Expression  =   {[math]::Round(($_.size/1073741824),2)}
}


$rawdisk = get-disk | Select-Object number, BusType,OperationalStatus,$size,PartitionStyle,size |
    Where-Object {$_.OperationalStatus -eq "Offline"}

    $rawdisk | Format-Table -AutoSize


$disklabelnum = @(
    @{DiskNumber = 1;   DiskLabel = "A_Data01"}     #LUN ID 0
    @{DiskNumber = 2;   DiskLabel = "A_Data02"}     #LUN ID 1
    @{DiskNumber = 3;   DiskLabel = "A_Index01"}    #LUN ID 2
    @{DiskNumber = 4;   DiskLabel = "A_Index02"}    #LUN ID 3
    @{DiskNumber = 5;   DiskLabel = "A_Log"}        #LUN ID 4
    @{DiskNumber = 6;   DiskLabel = "A Drive"}      #LUN ID 5
    @{DiskNumber = 7;   DiskLabel = "A_Backup"}     #LUN ID 6
)
$tempRootDrive  = 'E'
$myobject       = @()
$object         = @()

foreach($property in $disklabelnum){
    $diskinfo = (
        get-disk |
            Select-Object Number,
            BusType,
            OperationalStatus,
            PartitionStyle,
            $size,
            UniqueId |
            Where-Object {$_.Number -eq $property.DiskNumber}
    )

    $object = [ordered]@{
        DiskNumber          = $diskinfo.Number
        DiskName            = $property.DiskLabel
        UID                 = $diskinfo.UniqueId
        Capacity_Gb         = $diskinfo.Capacity_Gb
        StorageTear         = $diskinfo.BusType
        OperationalStatus   = $diskinfo.OperationalStatus
        PartitionStyle      = $diskinfo.PartitionStyle
    }

    $myobject += New-Object psobject -Property $object
}
$myobject  | Format-Table -AutoSize


foreach($LUN in $myobject){

    try{
        $isinitalized   = $false
        Initialize-Disk -Number $LUN.DiskNumber -PartitionStyle GPT -ErrorAction Stop
        $isinitalized   = $true
    }
    catch{
        $isinitalized = $true
        Write-Host "$($LUN.DiskName) is already initialized"
    }


    if($isinitalized -eq $true){
        write-host "Attempting to create partition to use on $($LUN.DiskName)"
        New-Partition -DiskNumber $LUN.DiskNumber -UseMaximumSize -DriveLetter $tempRootDrive | Out-Null

        Format-Volume -DriveLetter $tempRootDrive -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel $LUN.DiskName -Confirm:$false | Out-Null

        $partitionNumber = ((Get-Disk $LUN.DiskNumber | Get-Partition) | Select-Object * | Where-Object {$_.Type -eq 'basic'}).partitionNumber
        Start-Sleep -Seconds 3
        Remove-PartitionAccessPath -DiskNumber $LUN.DiskNumber -PartitionNumber $partitionNumber -AccessPath "$temprootdrive`:" Out-Null
    }
}

foreach($LUN in $myobject){
    if($LUN.DiskName -like '*drive'){
        $partitionNumber = ((Get-Disk $LUN.DiskNumber | Get-Partition) | Select-Object * | Where-Object {$_.Type -eq 'basic'}).partitionNumber
        Get-Partition -DiskNumber $Lun.DiskNumber -PartitionNumber $partitionNumber | Set-Partition -NewDriveLetter $tempRootDrive
    }
}