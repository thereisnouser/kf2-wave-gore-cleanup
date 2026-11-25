# Wave Gore Cleanup v0.1.0 - LOCAL SDK setup and optional build.
# Copies sources into the user KF2 KFGame\Src directory.
# This script DOES NOT touch X:\server\ or running KF2 server processes.
param(
    [switch]$Build,
    [switch]$Brew,
    [string]$SdkDir = ''
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $here 'Src\WaveGoreCleanup'
$docs = [Environment]::GetFolderPath('MyDocuments')
$userKF2 = Join-Path $docs 'My Games\KillingFloor2\KFGame'
$config = Join-Path $userKF2 'Config\KFEditor.ini'

if ([string]::IsNullOrWhiteSpace($SdkDir)) {
    $steamCommon = 'F:\Steam\steamapps\common'
    if (-not (Test-Path $steamCommon)) {
        throw 'SDK path not found. Pass -SdkDir to point to the KF2 SDK/game directory.'
    }
    $candidate = Get-ChildItem $steamCommon -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName 'Binaries\Win64\KFEditor.exe')
    } | Select-Object -First 1
    if (-not $candidate) {
        throw 'KFEditor.exe not found. Install Killing Floor 2 SDK via Steam, or pass -SdkDir.'
    }
    $SdkDir = $candidate.FullName
}

if (-not (Test-Path (Join-Path $SdkDir 'Development\Src'))) {
    throw "KF2 SDK UnrealScript source directory missing: $SdkDir\Development\Src"
}

$dst = Join-Path $userKF2 'Src\WaveGoreCleanup'
$classes = Join-Path $dst 'Classes'

if (-not (Test-Path (Join-Path $src 'Classes\WaveGoreCleanupMutator.uc'))) {
    throw "Source files not found in: $src"
}

New-Item -ItemType Directory -Path $classes -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $config -Parent) -Force | Out-Null

Get-ChildItem (Join-Path $src 'Classes') -Filter '*.uc' | ForEach-Object {
    $target = Join-Path $classes $_.Name
    if (Test-Path $target) {
        Copy-Item $target "$target.bak" -Force
    }
    Copy-Item $_.FullName $target -Force
}
Write-Host "[OK] Sources copied to User KF2 source folder: $classes" -ForegroundColor Green

# Preserve existing packages (such as a previous W4QoL prototype).
if (-not (Test-Path $config)) {
    '[ModPackages]' | Set-Content -Path $config -Encoding ASCII
}
$content = Get-Content $config -Raw
# This release renames W4WaveCleanup -> WaveGoreCleanup.
# Migrate the previous package entry instead of building two copies of the same mod.
if ($content -match '(?im)^\s*ModPackages\s*=\s*W4WaveCleanup\s*$') {
    Copy-Item $config "$config.bak" -Force
    $content = $content -replace '(?im)^(\s*ModPackages\s*=\s*)W4WaveCleanup(\s*)$', '${1}WaveGoreCleanup${2}'
    [System.IO.File]::WriteAllText($config, $content, [System.Text.Encoding]::ASCII)
}
if ($content -notmatch '(?im)^\s*ModPackages\s*=\s*WaveGoreCleanup\s*$') {
    Copy-Item $config "$config.bak" -Force
    if ($content -match '(?im)^\s*\[ModPackages\]\s*$') {
        $content = $content -replace '(?im)^\s*\[ModPackages\]\s*$',
            "[ModPackages]`r`nModPackages=WaveGoreCleanup"
    } else {
        $content = $content.TrimEnd() + "`r`n`r`n[ModPackages]`r`nModPackages=WaveGoreCleanup`r`n"
    }
    [System.IO.File]::WriteAllText($config, $content, [System.Text.Encoding]::ASCII)
}
Write-Host "[OK] KFEditor.ini registered WaveGoreCleanup: $config" -ForegroundColor Green

if (-not ($Build -or $Brew)) {
    Write-Host 'Sources are ready. Run with -Build after confirming SDK is installed.' -ForegroundColor Cyan
    exit 0
}

$editor = Join-Path $SdkDir 'Binaries\Win64\KFEditor.exe'
if (-not (Test-Path $editor)) {
    throw "KFEditor.exe not found: $editor"
}
$compiled = Join-Path $userKF2 'Unpublished\BrewedPC\Script\WaveGoreCleanup.u'
$backupDir = Join-Path $userKF2 'WaveGoreCleanupBuildBackups'

if (Test-Path $compiled) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $backup = Join-Path $backupDir "WaveGoreCleanup.$stamp.u"

    Move-Item $compiled $backup
    Write-Host "[OK] Previous package backed up: $backup"
}

$buildStarted = [DateTime]::UtcNow

Write-Host "[INFO] Running KFEditor make in: $SdkDir" -ForegroundColor Cyan

$proc = Start-Process -FilePath $editor `
    -WorkingDirectory (Split-Path $editor -Parent) `
    -ArgumentList @('make', '-useunpublished', '-log') `
    -PassThru -Wait

if ($proc.ExitCode -ne 0) {
    throw "Compilation failed. ExitCode=$($proc.ExitCode)"
}

if (-not (Test-Path $compiled)) {
    throw "Compilation output not found: $compiled"
}

$output = Get-Item $compiled

if ($output.LastWriteTimeUtc -lt $buildStarted -or $output.Length -eq 0) {
    throw "Compilation output is stale or empty"
}

$logPath = Join-Path $userKF2 'Logs\Launch.log'

if (-not (Test-Path $logPath)) {
    throw "Compiler log not found"
}

if ((Get-Item $logPath).LastWriteTimeUtc -lt $buildStarted) {
    throw "Compiler log is stale"
}

$buildLog = Get-Content $logPath -Raw

if ($buildLog -notmatch 'Success - 0 error\(s\), 0 warning\(s\)') {
    throw "Clean compilation not confirmed. Check $logPath"
}

Write-Host "[OK] Fresh package produced: $compiled" -ForegroundColor Green
Write-Host "[OK] Compilation: 0 errors, 0 warnings" -ForegroundColor Green

if ($Brew) {
    Write-Host '[INFO] Brewing WaveGoreCleanup...' -ForegroundColor Cyan
    $brewStartedUtc = [DateTime]::UtcNow
    $brewProcess = Start-Process -FilePath $editor `
        -WorkingDirectory (Split-Path $editor -Parent) `
        -ArgumentList @('brewcontent', '-platform=PC', 'WaveGoreCleanup', '-log') `
        -PassThru -Wait
    if ($brewProcess.ExitCode -ne 0) {
        throw "KFEditor brew exit code: $($brewProcess.ExitCode)"
    }

    $publishedCandidates = @(
        (Join-Path $SdkDir 'KFGame\Published\BrewedPC\WaveGoreCleanup.u'),
        (Join-Path $SdkDir 'KFGame\Published\BrewedPC\Script\WaveGoreCleanup.u'),
        (Join-Path $userKF2 'Published\BrewedPC\Script\WaveGoreCleanup.u'),
        (Join-Path $userKF2 'Published\BrewedPC\WaveGoreCleanup.u')
    )
    $published = $publishedCandidates |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        ForEach-Object { Get-Item -LiteralPath $_ } |
        Where-Object { $_.LastWriteTimeUtc -ge $brewStartedUtc -and $_.Length -gt 0 } |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1

    if (-not $published) {
        throw 'Fresh brewed WaveGoreCleanup.u not found in SDK or user Published folders. See SDK logs.'
    }

    $distDir = Join-Path $here 'dist\BrewedPC\Script'
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
    $distPackage = Join-Path $distDir 'WaveGoreCleanup.u'
    Copy-Item -LiteralPath $published.FullName -Destination $distPackage -Force
    $hash = (Get-FileHash -LiteralPath $published.FullName -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $distPackage -Algorithm SHA256).Hash -ne $hash) {
        throw 'Distribution package hash does not match brewed output.'
    }

    Write-Host "[OK] Brewed package: $distPackage" -ForegroundColor Green
    Write-Host "[OK] SHA256: $hash"
}

Write-Host '[CAUTION] Do not install this test package on ranked public servers.' -ForegroundColor Yellow
