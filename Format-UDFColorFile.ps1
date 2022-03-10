function Format-Colorfile {
    <# 1
    .SYNOPSIS
        Creates a colored listing of a folders files
    .DESCRIPTION
        Uses [System.Console]::ForegroundColor to control
        the color used to write out the file name.
        This is based on a PowerShell filter from
        the very first Monad book.
    .NOTES
    .EXAMPLE
        "Get-ChildItem c:\windows | Format-Colorfile "
        "https://github.com/dbaknack"
    .INPUTS
        output of Get-ChildItem #
    .OUTPUTS
        None
    .PARAMETER file
    #>
    #[CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [Parameter(ValueFromPipeline=$true)] $file
    )
    begin {
        $colors =   @{
            ps1         =   "Cyan";
            exe         =   "Green";
            cmd         =   "Green";
            directory   =   "Yellow"
    }
        $defaultColor   =   "White"
    }
    process {
        # condition where nothing is handled
        if ($file.Extension -ne "") {
            $ext = $file.Extension.Substring(1)
            Write-Output $ext
        }
        # condtion where extension is something
        if ($file.Mode.StartsWith("d")) {
            $ext = "directory" 
        }
        if ($colors.ContainsKey($ext)) {
            [System.Console]::ForegroundColor = $colors[$ext] 
        }
        $file
        [System.Console]::ForegroundColor = $defaultColor
    }
    end {
        [System.Console]::ForegroundColor = $defaultColor
    }
}