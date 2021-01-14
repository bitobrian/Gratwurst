$dateTimeNow = Get-Date -Format yyyy-MM-ddTHH-mm-ss-ff
$version = "_retail_"
$wowRetailPath  = "C:\Program Files (x86)\World of Warcraft\$version\Interface\AddOns"
$addonTempPath = Join-Path -Path $env:APPDATA -ChildPath "Gratwurst"
$addonPath  = Join-Path -Path $wowRetailPath -ChildPath "Gratwurst"
$backupAddonPath = Join-Path -Path $addonTempPath -ChildPath "Backup"

$addonPathExists = Test-Path -Path $addonPath
$tempPathExists = Test-Path -Path $addonTempPath

if(-not $tempPathExists){
    New-Item -Path $env:APPDATA -Name "Gratwurst" -ItemType "directory"
    Write-Host "TempFolderCreated"
}

if(-not $addonPathExists){
    New-Item -Path $addonPath -Name "Gratwurst" -ItemType "directory"
    Write-Host "AddonFolderCreated"
}

$allWowAddonFiles = $addonPath + "\*"

$backupAddonPathDateTime = Join-Path -Path $backupAddonPath -ChildPath $dateTimeNow

New-Item -Path $backupAddonPath -Name $dateTimeNow -ItemType "directory"

# Back up last session
Copy-Item -Path $allWowAddonFiles -Destination $backupAddonPathDateTime -Recurse

# Copy over source
Copy-Item -Path ".\Retail\*" -Destination $addonPath -Recurse

# Start-Process -FilePath "C:\Program Files (x86)\World of Warcraft\_retail_\Wow.exe"