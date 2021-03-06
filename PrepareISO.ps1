Param(  [int]$WindowsVersion,
        [string]$PathToISO,
        [string]$WindowsEdition,
        [string]$Language,
        [bool]$Log
    )

Import-Module "$PSScriptRoot\SurfUtil.psm1" -force | Out-Null

try {

    #Verifiy if ran in Admin
    $IsAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    if ($IsAdmin -eq $False) {
        Write-Host -ForegroundColor Red "Please use this script in an elevated Admin context"
        return $false
   }

    if ($Log -eq $true) {

        $OldVerboseLevel = $VerbosePreference
        $OldDebugLevel = $DebugPreference

        $VerbosePreference = "Continue"
        $DebugPreference = "Continue"

    }


    $DefaultFromConfigFile = Import-Config
    ($SurfModelHT,$OSReleaseHT,$SurfModelPS) = Import-SurfaceDB

    if ($PathToISO -eq "") {

        $localp = (Get-Item -Path ".\" -Verbose).FullName

        $IsoPath = $DefaultFromConfigFile["RootISO"]
        if ($null -eq $IsoPath) {
            $IsoPath = "$localp\Iso"
        }
        $PathToISO = $IsoPath
    }
    If(!(test-path $PathToISO)) {
        New-Item -ItemType Directory -Force -Path $PathToISO | out-null
    }

    if ($WindowsVersion -eq "") {

        $ios = (Get-WmiObject Win32_OperatingSystem | select-object BuildNumber).BuildNumber
        $WindowsVersion = (($OSReleaseHT.GetEnumerator()) | Where-Object { $_.Value -eq $ios }).Name

    }

    if ($WindowsEdition -eq "") {

        Write-Verbose "No Windows SKU parameter provided ... Looking to the default config file"
        $TargetSKU = $DefaultFromConfigFile["TargetSKU"]
        if ($TargetSKU -eq "") {
            Write-Host -ForegroundColor Red "Please specifiy a Windows Sku"
            return $false
        }
    }

    if ($Language -eq "") {

        Write-Verbose "No ISO language selector provided ... Looking to the default config file"
        $Language = $DefaultFromConfigFile["Language"]
        if ($Language -eq "") {
            $Language = "en"
        }
    } else {
        if ($Language.Length -gt 2) {
            Write-Host -ForegroundColor Red "Please enter a 2 characters code for language or specify nothing for 'en' "
            return $false
        }
    }

    Write-Host "Service Windows ISO for Windows [$WindowsVersion]"

    Write-Verbose "Calling Sync-WindowsISO -ISO '$IsoPath' -Version $WindowsVersion -TargetSKU '$TargetSKU' -Language $Language -Log $Log"
    Sync-WindowsISO -ISO $PathToISO -Version $WindowsVersion -TargetSKU $TargetSKU -Log $Log -Language $Language


}
catch [System.Exception] {
    Write-Host -ForegroundColor Red $_.Exception.Message;
    return $False
}
finally {
    if ($Log -eq $true) {

        write-verbose "Re establish initial verbosity"
        $VerbosePreference = $OldVerboseLevel
        $DebugPreference = $OldDebugLevel

    }
}