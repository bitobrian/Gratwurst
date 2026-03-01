param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Version,

    [Parameter(Position=1)]
    [string]$SourceDir = $PSScriptRoot
)
# package.ps1 <version> [source-dir]
# Stages addon files into .releases/<addon>/, substitutes @project-version@,
# and zips to .releases/<addon>-release-v<version>.zip

$ErrorActionPreference = "Stop"

Push-Location $SourceDir
try {
    # Discover .toc
    $tocFiles = @(Get-ChildItem -Path . -Filter "*.toc" -File)
    if ($tocFiles.Count -ne 1) {
        Write-Error "Expected exactly one .toc file, found $($tocFiles.Count)"
        exit 1
    }
    $AddonName = [System.IO.Path]::GetFileNameWithoutExtension($tocFiles[0].Name)
    $TagName   = "${AddonName}-release-v${Version}"
    $StageDir  = ".releases\${AddonName}"
    $ZipPath   = ".releases\${TagName}.zip"

    Write-Host "Addon:   ${AddonName}"
    Write-Host "Version: ${Version}"
    Write-Host "Output:  ${ZipPath}"

    # Stage
    if (Test-Path $StageDir) { Remove-Item $StageDir -Recurse -Force }
    New-Item -Path $StageDir -ItemType Directory -Force | Out-Null
    Copy-Item "${AddonName}.lua" $StageDir
    Copy-Item "${AddonName}.toc" $StageDir
    Copy-Item "${AddonName}.xml" $StageDir
    if (Test-Path "media" -PathType Container) {
        Copy-Item "media" $StageDir -Recurse
    }

    # Substitute version tokens
    $token = "@project-version@"
    foreach ($file in @("${StageDir}\${AddonName}.toc", "${StageDir}\${AddonName}.lua")) {
        $content = Get-Content $file -Raw
        if ($content -match [regex]::Escape($token)) {
            $content = $content -replace [regex]::Escape($token), $Version
            Set-Content $file -Value $content -NoNewline
        }
    }

    # Zip
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path $StageDir -DestinationPath $ZipPath

    Write-Host "Done: ${ZipPath}"
} finally {
    Pop-Location
}
