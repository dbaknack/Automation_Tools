function Convert-StorageVal {            
    [cmdletbinding()]            
    param(            
        [validateset(
            "Bytes","kb","mb","gb","tb")]
        [string]$From,
                   
        [validateset(
            "Bytes","kb","mb","gb","tb")]
        [string]$To,
                  
        [Parameter(
            mandatory         = $false,
            valuefrompipeline = $true)]
        [int[]]$Value
    )
    begin{
		<# empty begin block #>
    }
    process{
        foreach($val in $value){
            switch($from) {  
                "bytes" {
					$valResult = $val; break
				}
                "kb"    {
					$valResult = ($val * 1024); break
				}      
                "mb"    {
					$valResult = ($val * 1024 * 1024); break
				}     
                "gb"    {
					$valResult = ($val * 1024 * 1024 * 1024); break
				}
                "tb"    {
					$valResult = ($val * 1024 * 1024 * 1024) * 1024; break
				}
            }            
            
            switch ($to) {            
                "bytes" {
					$val
				}            
                "kb" {
					$valResult = $valResult/1KB; break
				}
                "mb" {
					$valResult = $valResult/1MB; break
				}
                "gb" {
					$valResult = $valResult/1GB; break
				}
                "tb" {
					$valResult = $valResult/1TB; break
				}
            }            
            $convertProp = @{
                "Size"   = [math]::round($valResult,2)
            }
            $converObj = new-object -typename psobject -property $convertProp
            Write-Output $converObj        
        }
    }
	end{
		<# empty end block #>
	}
}
