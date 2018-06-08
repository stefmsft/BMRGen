Import-Module "$PSScriptRoot\SurfUtil.psm1" -force | Out-Null

try {

    #Verifiy if ran in Admin
    $IsAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    if ($IsAdmin -eq $False) {
        Write-Host -ForegroundColor Red "Please use this script in an elevated Admin context"
        return $false
    }

    ($SurfModelHT,$OSReleaseHT) = Import-SurfaceDB

    $MachineModel = (Get-WmiObject -namespace root\wmi -class MS_SystemInformation | select-object SystemSKU).SystemSKU
    
    if ($MachineModel -eq "Surface_Pro_1807") {
        $SurfaceModel = "Surface Pro Lte"
    }
    elseif ($MachineModel -eq "Surface_Pro_1796") {
        $SurfaceModel = "Surface Pro"
    }
    elseif ($MachineModel -eq "Surface_Book") {
        $SurfaceModel = "Surface Book"
    }
    elseif ($MachineModel -eq "Surface_Book_1832") {
        $SurfaceModel = "Surface Book"
    }
    elseif ($MachineModel -eq "Surface_Book_1793") {
        $SurfaceModel = "Surface Book"
    }
    elseif ($MachineModel -eq "Surface_Pro_4") {
        $SurfaceModel = "Surface Pro4"
    }
    elseif ($MachineModel -eq "Surface_Pro_3") {
        $SurfaceModel = "Surface Pro3"
    }
    elseif ($MachineModel -eq "Surface_Studio") {
        $SurfaceModel = "Surface Studio"
    }
    elseif ($MachineModel -eq "Surface_Laptop") {
        $SurfaceModel = "Surface Laptop"
    }

    Write-Verbose "Model : $SurfaceModel"

    $DefaultFromConfigFile = Import-Config
    
    $localp = (Get-Item -Path ".\" -Verbose).FullName

    $RepoPath = $DefaultFromConfigFile["RootRepo"]
    if ($RepoPath -eq $null) {
        $RepoPath = "$localp\Repo"
    }

    If(!(test-path $RepoPath)) {
            New-Item -ItemType Directory -Force -Path $repopath | out-null
    }
    
    $LocalRepoPathDir = resolve-path $RepoPath
    write-debug "Full Path Repo is : $LocalRepoPathDir"

    $ios = (Get-WmiObject Win32_OperatingSystem | select-object BuildNumber).BuildNumber
    $os = (($OSReleaseHT.GetEnumerator()) | Where-Object { $_.Value -eq $ios }).Name

    $ret = Import-SurfaceDrivers -Model $SurfaceModel -WindowsVersion $os -RepoPath $LocalRepoPathDir -Apply $True
    if ($ret -eq $False) {
        Write-Host "No Drivers found for the current OS ... Looking for previous versions"
        $ret = Import-SurfaceDrivers -Model $SurfaceModel -RepoPath $LocalRepoPathDir -Apply $True
    }

}
catch [System.Exception] {
    Write-Host -ForegroundColor Red $_.Exception.Message;
    return $False
}