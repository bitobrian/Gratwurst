param(
    [Parameter(Position=0)]
    [ValidateSet("clean", "copy", "backup", "help")]
    [string]$Action = "copy",
    
    [string]$WowPath = "",
    [string]$AddonName = "Gratwurst"
)

# Configuration
$dateTimeNow = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$version = "_retail_"

# Determine WoW path
if ([string]::IsNullOrEmpty($WowPath)) {
    $possiblePaths = @(
        "C:\Program Files (x86)\World of Warcraft",
        "C:\Program Files\World of Warcraft",
        "${env:ProgramFiles(x86)}\World of Warcraft",
        "$env:ProgramFiles\World of Warcraft"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $WowPath = $path
            break
        }
    }
    
    if ([string]::IsNullOrEmpty($WowPath)) {
        Write-Error "Could not find World of Warcraft installation. Please specify -WowPath parameter."
        exit 1
    }
}

# Paths
$wowAddonsPath = Join-Path -Path $WowPath -ChildPath "$version\Interface\AddOns"
$addonPath = Join-Path -Path $wowAddonsPath -ChildPath $AddonName
$backupRootPath = Join-Path -Path $env:APPDATA -ChildPath "$AddonName-Backups"
$backupPath = Join-Path -Path $backupRootPath -ChildPath $dateTimeNow
$sourcePath = $PSScriptRoot

# Colors for output
$colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Path = "Blue"
}

function Write-Status {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $formattedMessage = "[$timestamp] $Message"
    
    if ($NoNewline) {
        Write-Host $formattedMessage -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $formattedMessage -ForegroundColor $Color
    }
}

function Test-RequiredFiles {
    $requiredFiles = @("Gratwurst.lua", "Gratwurst.toc", "Gratwurst.xml")
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path -Path $sourcePath -ChildPath $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Status "Missing required files: $($missingFiles -join ', ')" $colors.Error
        return $false
    }
    
    Write-Status "All required files found" $colors.Success
    return $true
}

function Backup-ExistingAddon {
    if (-not (Test-Path $addonPath)) {
        Write-Status "No existing addon found to backup" $colors.Warning
        return
    }
    
    try {
        # Create backup directory
        if (-not (Test-Path $backupRootPath)) {
            New-Item -Path $backupRootPath -ItemType Directory -Force | Out-Null
        }
        
        # Create timestamped backup
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        
        # Copy existing addon to backup
        Copy-Item -Path "$addonPath\*" -Destination $backupPath -Recurse -Force
        
        Write-Status "Backup created at: $backupPath" $colors.Success
    }
    catch {
        Write-Status "Failed to create backup: $($_.Exception.Message)" $colors.Error
        throw
    }
}

function Remove-ExistingAddon {
    if (Test-Path $addonPath) {
        try {
            Remove-Item -Path $addonPath -Recurse -Force
            Write-Status "Removed existing addon" $colors.Success
        }
        catch {
            Write-Status "Failed to remove existing addon: $($_.Exception.Message)" $colors.Error
            throw
        }
    } else {
        Write-Status "No existing addon found" $colors.Warning
    }
}

function Copy-AddonFiles {
    try {
        # Create addon directory
        New-Item -Path $addonPath -ItemType Directory -Force | Out-Null
        
        # Copy all files from source
        $sourceFiles = Get-ChildItem -Path $sourcePath -File | Where-Object { 
            $_.Name -notlike "*.ps1" -and 
            $_.Name -notlike "*.md" -and 
            $_.Name -notlike "*.txt" -and
            $_.Name -notlike "dev-plan*" -and
            $_.Name -notlike "test*" -and
            $_.Name -notlike "CHANGELOG*"
        }
        
        foreach ($file in $sourceFiles) {
            Copy-Item -Path $file.FullName -Destination $addonPath -Force
            Write-Status "Copied: $($file.Name)" $colors.Info
        }
        
        # Copy media folder if it exists
        $mediaPath = Join-Path -Path $sourcePath -ChildPath "media"
        if (Test-Path $mediaPath) {
            Copy-Item -Path $mediaPath -Destination $addonPath -Recurse -Force
            Write-Status "Copied media folder" $colors.Info
        }
        
        Write-Status "Addon copied successfully!" $colors.Success
        Write-Status "Installation path: $addonPath" $colors.Path
    }
    catch {
        Write-Status "Failed to copy addon files: $($_.Exception.Message)" $colors.Error
        throw
    }
}

function Show-Help {
    Write-Host @"
Gratwurst Addon Copy Script
===========================

Usage: .\Copy-Addon.ps1 [Action] [-WowPath <path>] [-AddonName <name>]

Actions:
  copy    - Copy addon to WoW directory (default)
  backup  - Create backup of existing addon
  clean   - Remove addon from WoW directory
  help    - Show this help message

Parameters:
  -WowPath    - Custom WoW installation path
  -AddonName  - Custom addon name (default: Gratwurst)

Examples:
  .\Copy-Addon.ps1                    # Copy addon
  .\Copy-Addon.ps1 backup             # Create backup only
  .\Copy-Addon.ps1 clean              # Remove addon
  .\Copy-Addon.ps1 -WowPath "D:\Games\WoW"  # Custom WoW path

"@ -ForegroundColor Cyan
}

# Main execution
Write-Status "=== Gratwurst Addon Copy Script ===" $colors.Info
Write-Status "Action: $Action" $colors.Info
Write-Status "WoW Path: $WowPath" $colors.Path
Write-Status "Addon Name: $AddonName" $colors.Path
Write-Status "Source Path: $sourcePath" $colors.Path
Write-Host

try {
    switch ($Action.ToLower()) {
        "help" {
            Show-Help
        }
        "clean" {
            Write-Status "Cleaning addon installation..." $colors.Warning
            Remove-ExistingAddon
            Write-Status "Cleanup completed" $colors.Success
        }
        "backup" {
            Write-Status "Creating backup..." $colors.Info
            Backup-ExistingAddon
            Write-Status "Backup completed" $colors.Success
        }
        "copy" {
            Write-Status "Starting addon copy process..." $colors.Info
            
            # Validate source files
            if (-not (Test-RequiredFiles)) {
                exit 1
            }
            
            # Create backup of existing addon
            Backup-ExistingAddon
            
            # Remove existing addon
            Remove-ExistingAddon
            
            # Copy new addon
            Copy-AddonFiles
            
            Write-Status "=== Copy process completed successfully! ===" $colors.Success
        }
        default {
            Write-Status "Unknown action: $Action" $colors.Error
            Show-Help
            exit 1
        }
    }
}
catch {
    Write-Status "Script failed: $($_.Exception.Message)" $colors.Error
    exit 1
}



