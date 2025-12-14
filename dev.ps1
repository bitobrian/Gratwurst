param(
    [Parameter(Position=0)]
    [ValidateSet("clean", "copy", "backup", "scan", "help")]
    [string]$Action = "copy",
    
    [string]$WowPath = "",
    [string]$AddonName = "Gratwurst",

    [switch]$Beta,

    [switch]$DeepScan
)

# Configuration
$dateTimeNow = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$versionMap = @{
    retail = "_retail_"
    beta   = "_beta_"
}

$targetFlavor = if ($Beta) { "beta" } else { "retail" }
$version = $versionMap[$targetFlavor]

if ([string]::IsNullOrEmpty($version)) {
    Write-Error "Unknown flavor '$Flavor'."
    exit 1
}

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

function Resolve-FlavorFolder {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FlavorName
    )

    if (-not $versionMap.ContainsKey($FlavorName)) {
        return $null
    }

    return $versionMap[$FlavorName]
}

function Get-WoWInstallations {
    param(
        [switch]$Deep
    )

    # Only look for retail and beta folders
    $flavorFolders = @("_retail_", "_beta_")

    $candidateRoots = New-Object System.Collections.Generic.List[string]

    $commonRoots = @(
        "C:\Program Files (x86)\World of Warcraft",
        "C:\Program Files\World of Warcraft",
        "${env:ProgramFiles(x86)}\World of Warcraft",
        "$env:ProgramFiles\World of Warcraft",
        "C:\Games\World of Warcraft",
        "D:\Games\World of Warcraft",
        "D:\World of Warcraft",
        "E:\World of Warcraft"
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique

    foreach ($root in $commonRoots) {
        if (Test-Path $root) {
            $resolved = (Resolve-Path -LiteralPath $root -ErrorAction SilentlyContinue)
            $normalized = if ($resolved) { $resolved.Path } else { $root }
            if (-not $candidateRoots.Contains($normalized)) {
                $candidateRoots.Add($normalized)
            }
        }
    }

    if ($Deep) {
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
        $searchRoots = @("Games", "Blizzard", "Battle.net", "Program Files", "Program Files (x86)")

        foreach ($drive in $drives) {
            foreach ($folder in $searchRoots) {
                $base = Join-Path -Path $drive.Root -ChildPath $folder
                if (-not (Test-Path $base)) { continue }

                try {
                    $found = Get-ChildItem -Path $base -Directory -Recurse -Depth 4 -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -eq "World of Warcraft" } |
                        Select-Object -ExpandProperty FullName
                    foreach ($f in $found) {
                        $resolved = (Resolve-Path -LiteralPath $f -ErrorAction SilentlyContinue)
                        $normalized = if ($resolved) { $resolved.Path } else { $f }
                        if (-not $candidateRoots.Contains($normalized)) {
                            $candidateRoots.Add($normalized)
                        }
                    }
                } catch {
                    # Best-effort scanning only
                }
            }
        }
    }

    $installations = New-Object System.Collections.Generic.List[object]
    foreach ($root in ($candidateRoots | Sort-Object -Unique)) {
        foreach ($flavorFolder in $flavorFolders) {
            $flavorPath = Join-Path -Path $root -ChildPath $flavorFolder
            $addonsPath = Join-Path -Path $flavorPath -ChildPath "Interface\\AddOns"
            
            # Check if this flavor folder exists (as a directory)
            if (-not (Test-Path -PathType Container $flavorPath)) {
                continue
            }
            
            # Look for exe in the flavor folder
            $wowExe = Join-Path -Path $flavorPath -ChildPath "Wow.exe"
            $wowExe64 = Join-Path -Path $flavorPath -ChildPath "WowClassic.exe"
            $exe = if (Test-Path $wowExe) { $wowExe } elseif (Test-Path $wowExe64) { $wowExe64 } else { $null }
            
            $installations.Add([pscustomobject]@{
                RootPath   = $root
                FlavorPath = $flavorFolder
                AddOnsPath = $addonsPath
                ExePath    = $exe
            })
        }
    }

    # Return installations sorted by root path and flavor (retail first, then beta)
    return @($installations |
        Sort-Object RootPath, @{ Expression = { $_.FlavorPath } ; Descending = $true })
}

function Resolve-WoWInstallation {
    param(
        [string]$ExplicitWowPath,
        [switch]$UseBeta,
        [switch]$Deep
    )

    if (-not [string]::IsNullOrEmpty($ExplicitWowPath)) {
        if (-not (Test-Path $ExplicitWowPath)) {
            throw "Provided -WowPath does not exist: $ExplicitWowPath"
        }
        # When explicit path is given, use beta if -UseBeta is set
        $flavorPath = if ($UseBeta) { "_beta_" } else { "_retail_" }
        return [pscustomobject]@{
            RootPath   = $ExplicitWowPath
            FlavorPath = $flavorPath
        }
    }

    $installs = @(Get-WoWInstallations -Deep:$Deep)
    if ($installs.Count -eq 0) {
        throw "Could not find a World of Warcraft installation. Use -WowPath or run: .\\dev.ps1 scan"
    }

    # Determine which flavor to use
    $targetFlavor = if ($UseBeta) { "_beta_" } else { "_retail_" }
    
    # Find an install matching the target flavor
    $matching = @($installs | Where-Object { $_.FlavorPath -eq $targetFlavor })
    if ($matching.Count -gt 0) {
        return $matching[0]
    }

    # If target not found but only 1 install exists, use it
    if ($installs.Count -eq 1) {
        return $installs[0]
    }

    # Ambiguous: can't find the target flavor and multiple installs exist
    Write-Status "Could not find WoW $targetFlavor. Available installations:" $colors.Warning
    for ($i = 0; $i -lt $installs.Count; $i++) {
        $it = $installs[$i]
        Write-Host ("  - {0} {1}" -f $it.RootPath, $it.FlavorPath)
    }
    throw "Run .\\dev.ps1 scan to see available options."
}

function Get-AddonSourceRoot {
    param(
        [string]$Path
    )

    if (-not [string]::IsNullOrEmpty($Path)) {
        return (Resolve-Path $Path).Path
    }
    return $PSScriptRoot
}

function Get-AddonInstallPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WowRoot,
        [Parameter(Mandatory=$true)]
        [string]$FlavorFolder,
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    $addonsRoot = Join-Path -Path $WowRoot -ChildPath "$FlavorFolder\\Interface\\AddOns"
    return (Join-Path -Path $addonsRoot -ChildPath $Name)
}

# Paths (resolved later after WoW path detection)
$sourcePath = Get-AddonSourceRoot
$backupRootPath = Join-Path -Path $env:APPDATA -ChildPath "$AddonName-Backups"
$backupPath = Join-Path -Path $backupRootPath -ChildPath $dateTimeNow

function Test-RequiredFiles {
    # Generic default: require a TOC for the named addon. If it doesn't exist,
    # fall back to "any .toc" to support repos where folder name != toc name.
    $requiredFiles = @("$AddonName.toc")
    $missingFiles = @()

    foreach ($file in $requiredFiles) {
        $filePath = Join-Path -Path $sourcePath -ChildPath $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }

    if ($missingFiles.Count -gt 0) {
        $anyToc = Get-ChildItem -Path $sourcePath -Filter "*.toc" -File -ErrorAction SilentlyContinue
        if ($null -eq $anyToc -or $anyToc.Count -eq 0) {
            Write-Status "Missing required addon metadata (.toc). Expected '$AddonName.toc' or any '*.toc' in: $sourcePath" $colors.Error
            return $false
        }
        Write-Status "'$AddonName.toc' not found; proceeding because a .toc exists: $($anyToc[0].Name)" $colors.Warning
        return $true
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

        # Copy files/folders from source, excluding dev/docs/meta.
        $excludedRootNames = @(
            ".git",
            ".github",
            ".vscode",
            "backlog",
            "node_modules"
        )

        $excludedFileNames = @(
            "dev.ps1",
            "pkgmeta.yaml"
        )

        $excludedExtensions = @(".md", ".txt")

        $items = Get-ChildItem -Path $sourcePath -Force
        foreach ($item in $items) {
            if ($item.PSIsContainer -and ($excludedRootNames -contains $item.Name)) {
                continue
            }
            if (-not $item.PSIsContainer) {
                if ($excludedFileNames -contains $item.Name) { continue }
                if ($excludedExtensions -contains $item.Extension.ToLowerInvariant()) { continue }
                if ($item.Name -like "dev-plan*") { continue }
                if ($item.Name -like "test*") { continue }
                if ($item.Name -like "CHANGELOG*") { continue }
            }

            Copy-Item -Path $item.FullName -Destination $addonPath -Recurse -Force
            Write-Status "Copied: $($item.Name)" $colors.Info
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
Addon Dev Script
===========================

Usage: .\dev.ps1 [Action] [-Beta] [-WowPath <path>] [-AddonName <name>] [-DeepScan]

Actions:
  copy    - Copy addon to WoW directory (default)
  backup  - Create backup of existing addon
  clean   - Remove addon from WoW directory
  scan    - List detected WoW installations
  help    - Show this help message

Parameters:
  -Beta       - Target beta install instead of retail
  -WowPath    - Custom WoW installation path (overrides auto-detect)
  -AddonName  - Custom addon name (default: Gratwurst)
  -DeepScan   - Search more drives (slower)

Examples:
  .\dev.ps1                    # Copy addon to retail
  .\dev.ps1 -Beta              # Copy addon to beta
  .\dev.ps1 backup             # Backup only
  .\dev.ps1 clean              # Remove addon
  .\dev.ps1 scan               # Show detected installations
  .\dev.ps1 -Beta -DeepScan    # Copy to beta with deeper folder search

"@ -ForegroundColor Cyan
}

# Resolve WoW paths now that functions are defined
$resolvedWowPath = $null
$resolvedFlavorFolder = $null
$wowAddonsPath = $null
$addonPath = $null

if ($Action.ToLower() -ne "help") {
    try {
        if ($Action.ToLower() -eq "scan") {
            # scan action doesn't require resolving a single target path
        } else {
            $install = Resolve-WoWInstallation -ExplicitWowPath $WowPath -UseBeta:$Beta -Deep:$DeepScan
            $resolvedWowPath = $install.RootPath
            $resolvedFlavorFolder = $install.FlavorPath
            $wowAddonsPath = Join-Path -Path $resolvedWowPath -ChildPath "$resolvedFlavorFolder\\Interface\\AddOns"
            $addonPath = Join-Path -Path $wowAddonsPath -ChildPath $AddonName
        }
    } catch {
        Write-Status $_ $colors.Error
        exit 1
    }
}

# Main execution
Write-Status "=== Addon Dev Script ===" $colors.Info
Write-Status "Action: $Action" $colors.Info
Write-Status "Addon Name: $AddonName" $colors.Path
if ($resolvedFlavorFolder) {
    $flavorLabel = if ($Beta) { "beta" } else { "retail" }
    Write-Status "Target: $flavorLabel" $colors.Info
}
if (-not [string]::IsNullOrEmpty($resolvedWowPath)) {
    Write-Status "WoW Path: $resolvedWowPath" $colors.Path
    Write-Status "AddOns Path: $wowAddonsPath" $colors.Path
}
Write-Status "Source Path: $sourcePath" $colors.Path
Write-Host

try {
    switch ($Action.ToLower()) {
        "help" {
            Show-Help
        }
        "scan" {
            Write-Status "Scanning for WoW installs..." $colors.Info
            $installs = @(Get-WoWInstallations -PreferFlavor $Flavor -Deep:$DeepScan)
            if ($installs.Count -eq 0) {
                Write-Status "No installs detected. Try -DeepScan or specify -WowPath." $colors.Warning
                exit 1
            }
            Write-Status "Found $($installs.Count) WoW installation(s):" $colors.Success
            for ($i = 0; $i -lt $installs.Count; $i++) {
                $it = $installs[$i]
                $flavor = if ($it.FlavorPath -eq "_beta_") { "beta" } else { "retail" }
                Write-Host ("[{0}] {1} ({2})" -f $i, $it.RootPath, $flavor) -ForegroundColor $colors.Path
                Write-Host ("     > AddOns: {0}" -f $it.AddOnsPath)
            }
            Write-Host
            Write-Status "Use -Beta flag to copy to beta, or specify -WowPath for custom location." $colors.Info
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



