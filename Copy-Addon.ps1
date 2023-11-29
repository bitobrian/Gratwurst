$options = $args[0]

$addonTestName = "Gratwurst"
$dateTimeNow = Get-Date -Format yyyy-MM-ddTHH-mm-ss-ff
$version = "_retail_"
$wowRetailPath  = "C:\Program Files (x86)\World of Warcraft\$version\Interface\AddOns"
$addonTempPath = Join-Path -Path $env:APPDATA -ChildPath $addonTestName
$addonPath  = Join-Path -Path $wowRetailPath -ChildPath $addonTestName
$backupAddonPath = Join-Path -Path $addonTempPath -ChildPath "Backup"

$addonPathExists = Test-Path -Path $addonPath
$tempPathExists = Test-Path -Path $addonTempPath

function Clear-Folders {
    if($addonPathExists){
        Remove-Item -Path $addonPath -Recurse -Force
        Write-Host "AddonFolderRemoved"
    }

    if($tempPathExists){
        Remove-Item -Path $addonTempPath -Recurse -Force
        Write-Host "TempFolderRemoved"
    }
}

function Copy-Addon {
    if(-not $tempPathExists){
        New-Item -Path $env:APPDATA -Name $addonTestName -ItemType "directory"
    }
    
    if(-not $addonPathExists){
        New-Item -Path $addonPath -Name $addonTestName -ItemType "directory"
    }
    
    $allWowAddonFiles = $addonPath + "\*"
    
    $backupAddonPathDateTime = Join-Path -Path $backupAddonPath -ChildPath $dateTimeNow
    
    New-Item -Path $backupAddonPath -Name $dateTimeNow -ItemType "directory"
    
    # Back up last session
    Copy-Item -Path $allWowAddonFiles -Destination $backupAddonPathDateTime -Recurse
    
    Copy-Item -Path "src\*" -Destination $addonPath -Recurse -Force

    Write-Host $addonPath -ForegroundColor Blue
}

# switch on args
switch ($options) {
    "clean" {
        Write-Host "Cleaning up addon"
        Clear-Folders
    }
    default {
        Write-Host "Copying addon"
        Copy-Addon
    }
}



