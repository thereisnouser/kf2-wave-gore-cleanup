# Wave Gore Cleanup v0.1.0 - LOCAL SDK setup and optional build.
# This script DOES NOT touch X:\server\ or running KF2 server processes.
param(
    [switch]$Build,
    [string]$SdkDir = ''
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $here 'Src\WaveGoreCleanup'
$docs = [Environment]::GetFolderPath('MyDocuments')
$userKF2 = Join-Path $docs 'My Games\KillingFloor2\KFGame'
$dst = Join-Path $userKF2 'Src\WaveGoreCleanup'
$classes = Join-Path $dst 'Classes'
$config = Join-Path $userKF2 'Config\KFEditor.ini'

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
Write-Host "[OK] Sources copied to $classes" -ForegroundColor Green

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

if (-not $Build) {
    Write-Host 'Sources are ready. Run with -Build after confirming SDK is installed.' -ForegroundColor Cyan
    exit 0
}

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

$editor = Join-Path $SdkDir 'Binaries\Win64\KFEditor.exe'
if (-not (Test-Path $editor)) {
    throw "KFEditor.exe not found: $editor"
}
Write-Host "[INFO] Running KFEditor make in: $SdkDir" -ForegroundColor Cyan
$proc = Start-Process -FilePath $editor -WorkingDirectory (Split-Path $editor -Parent) `
    -ArgumentList @('make', '-useunpublished', '-log') -PassThru -Wait

$compiled = Join-Path $userKF2 'Unpublished\BrewedPC\Script\WaveGoreCleanup.u'
if (-not (Test-Path $compiled)) {
    throw "Compilation output not found: $compiled. Check KFEditor logs. ExitCode=$($proc.ExitCode)"
}
Write-Host "[OK] Package produced: $compiled" -ForegroundColor Green
Write-Host '[CAUTION] Do not install this test package on ranked public servers.' -ForegroundColor Yellow
