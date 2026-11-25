[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SdkDir,
    [string]$PreviewPath = (Join-Path $PSScriptRoot 'icon.png'),
    [switch]$Upload
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$binary = Join-Path $PSScriptRoot 'dist\BrewedPC\Script\WaveGoreCleanup.u'
$preview = $PreviewPath
$descriptionFile = Join-Path $PSScriptRoot 'workshop\description.txt'
$tool = Join-Path $SdkDir 'Binaries\WorkshopUserTool.exe'

foreach ($path in @($binary, $preview, $descriptionFile, $tool)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0) {
        throw "Required file missing or empty: $path"
    }
}
if ((Get-Item -LiteralPath $preview).Length -ge 1MB) {
    throw 'Preview image must be smaller than 1 MB for this uploader.'
}

$preview = (Resolve-Path -LiteralPath $preview).Path
if ([System.IO.Path]::GetExtension($preview) -ine '.png') {
    throw 'Workshop preview must be a PNG file.'
}

$description = [System.IO.File]::ReadAllText($descriptionFile).Trim()
if ($description.Contains('"')) {
    throw 'Workshop description must not contain double quotation marks.'
}

# The uploader expects the metadata filename relative to the KF2 user directory.
$documents = [Environment]::GetFolderPath('MyDocuments')
if ([string]::IsNullOrWhiteSpace($documents)) {
    throw 'Windows Documents directory could not be resolved.'
}
$userDir = Join-Path $documents 'My Games\KillingFloor2'
if (-not (Test-Path -LiteralPath $userDir -PathType Container)) {
    throw "KF2 user directory not found: $userDir"
}

$dist = Join-Path $PSScriptRoot 'dist'
$attemptFile = Join-Path $dist 'workshop-upload-attempt.txt'
# A persistent record survives a new build; do not remove it after an upload attempt.
if ($Upload -and (Test-Path -LiteralPath $attemptFile)) {
    throw 'An upload was already attempted from this checkout. Check your Steam Workshop items before trying again. Do not use this script to update a published item until its update workflow is verified.'
}

# A fresh directory prevents other SDK packages from being accidentally uploaded.
$stage = Join-Path $dist ('workshop-' + [guid]::NewGuid().ToString('N'))
$content = Join-Path $stage 'content'
$scriptDir = Join-Path $content 'BrewedPC\Script'
New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
$stagedBinary = Join-Path $scriptDir 'WaveGoreCleanup.u'
Copy-Item -LiteralPath $binary -Destination $stagedBinary
Copy-Item -LiteralPath $preview -Destination (Join-Path $stage 'preview.png')
if ((Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash -ne
    (Get-FileHash -LiteralPath $stagedBinary -Algorithm SHA256).Hash) {
    throw 'Staged package does not match the original build.'
}

$previewPath = Join-Path $stage 'preview.png'
$metadata = @(
    ('$Description "{0}"' -f $description)
    '$Title "Wave Gore Cleanup"'
    ('$PreviewFile "{0}"' -f $previewPath)
    '$Tags "Mutators"'
    '$MicroTxItem "false"'
    ('$PackageDirectory "{0}"' -f $content)
)
$metadataFile = Join-Path $stage 'wsinfo_WaveGoreCleanup.txt'
[System.IO.File]::WriteAllLines($metadataFile, [string[]]$metadata, [System.Text.UTF8Encoding]::new($false))

Write-Host "Workshop staging: $stage"
Write-Host "Metadata: $metadataFile"
Write-Host 'Package: WaveGoreCleanup.u | Category: Mutators | Test build'
Write-Host ('SHA256: ' + (Get-FileHash -LiteralPath $stagedBinary -Algorithm SHA256).Hash)
if (-not $Upload) {
    Write-Host "Preparation only. Nothing was uploaded."
    return
}

if (-not (Get-Process -Name steam -ErrorAction SilentlyContinue)) {
    throw 'Start Steam and sign in to the account that will own the Workshop item.'
}
if ((Read-Host 'First publication only. Check you have no existing Wave Gore Cleanup item. Type PUBLISH to proceed') -cne 'PUBLISH') {
    Write-Host 'Upload cancelled.'
    return
}

$metadataName = 'wsinfo_WaveGoreCleanup_' + [guid]::NewGuid().ToString('N') + '.txt'
$userMetadata = Join-Path $userDir $metadataName
Copy-Item -LiteralPath $metadataFile -Destination $userMetadata
# Keep an attempt record even on failure: Steam may have created an item.
$record = @("Metadata: $userMetadata", "Stage: $stage", "UTC: $([DateTime]::UtcNow.ToString('o'))")
$attemptStream = [System.IO.File]::Open($attemptFile, [System.IO.FileMode]::CreateNew)
try {
    $recordBytes = [System.Text.Encoding]::UTF8.GetBytes(($record -join [Environment]::NewLine))
    $attemptStream.Write($recordBytes, 0, $recordBytes.Length)
}
finally {
    $attemptStream.Dispose()
}

Push-Location (Split-Path -Parent $tool)
try {
    & $tool $metadataName
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}
if ($exitCode -ne 0) {
    throw "Workshop uploader exit code: $exitCode. Check Steam and its output before retrying."
}
Write-Host 'Uploader exited. Verify the success message and the item in Steam Workshop; an exit code alone is not proof of publication.'
Write-Host 'Keep the Workshop item ID for future updates. Do not rerun first publication.'
