[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ApkPath = 'build/app/outputs/flutter-apk/app-dev-release.apk',
    [string]$OutputDirectory = 'build/demo'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
function GitValue([string[]]$Arguments) {
    $result = & git -C $RepositoryRoot @Arguments
    if ($LASTEXITCODE -ne 0) { throw 'Git verification failed.' }
    return ($result | Out-String).Trim()
}
function Sha256([byte[]]$Bytes) {
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}
function ZipBytes($Archive, [string]$Name) {
    $entries = @($Archive.Entries | Where-Object FullName -eq $Name)
    if ($entries.Count -ne 1) { throw "APK asset missing or duplicated: $Name" }
    $stream = $entries[0].Open()
    $buffer = [IO.MemoryStream]::new()
    try { $stream.CopyTo($buffer); return ,$buffer.ToArray() }
    finally { $stream.Dispose(); $buffer.Dispose() }
}

$commit = GitValue @('rev-parse', 'HEAD')
if ($commit -notmatch '^[a-f0-9]{40}$') { throw 'Invalid source commit.' }
if (GitValue @('status', '--porcelain')) { throw 'Demo requires a clean checkout.' }
$apk = if ([IO.Path]::IsPathRooted($ApkPath)) { $ApkPath } else { Join-Path $RepositoryRoot $ApkPath }
$output = if ([IO.Path]::IsPathRooted($OutputDirectory)) { $OutputDirectory } else { Join-Path $RepositoryRoot $OutputDirectory }
if (Test-Path -LiteralPath $output) { throw 'Output already exists; do not overwrite a prior package.' }
$manifestPath = Join-Path $RepositoryRoot 'assets/models/model-manifest.v1.json'
$manifestBytes = [IO.File]::ReadAllBytes($manifestPath)
$manifest = [Text.Encoding]::UTF8.GetString($manifestBytes) | ConvertFrom-Json
$apkHash = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
$modelBytes = [IO.File]::ReadAllBytes((Join-Path $RepositoryRoot 'assets/models/efficientdet-lite0.tflite'))
if ((Sha256 $modelBytes) -ne $manifest.artifact.sha256 -or $modelBytes.Length -ne $manifest.artifact.size_bytes) {
    throw 'Source model hash/size mismatch.'
}
$archive = [IO.Compression.ZipFile]::OpenRead($apk)
try {
    $embeddedManifest = ZipBytes $archive 'assets/flutter_assets/assets/models/model-manifest.v1.json'
    $embeddedModel = ZipBytes $archive 'assets/flutter_assets/assets/models/efficientdet-lite0.tflite'
    if ((Sha256 $embeddedManifest) -ne (Sha256 $manifestBytes)) { throw 'APK manifest differs from source.' }
    if ((Sha256 $embeddedModel) -ne $manifest.artifact.sha256 -or $embeddedModel.Length -ne $manifest.artifact.size_bytes) {
        throw 'APK model hash/size mismatch.'
    }
} finally { $archive.Dispose() }

$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
if (-not $sdk) {
    $properties = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'android/local.properties')
    $sdkLine = @($properties | Where-Object { $_.StartsWith('sdk.dir=') })
    if ($sdkLine.Count -ne 1) { throw 'Android SDK path unavailable.' }
    $sdk = $sdkLine[0].Substring(8).Replace('\\', '\').Replace('\:', ':')
}
$buildTools = Get-ChildItem -LiteralPath (Join-Path $sdk 'build-tools') -Directory |
    Where-Object Name -Match '^\d+\.\d+\.\d+$' | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
if (-not $buildTools) { throw 'Stable Android build tools unavailable.' }
$signer = Join-Path $buildTools.FullName $(if ($IsWindows) { 'apksigner.bat' } else { 'apksigner' })
$aapt = Join-Path $buildTools.FullName $(if ($IsWindows) { 'aapt.exe' } else { 'aapt' })
$signature = & $signer verify --verbose --print-certs $apk 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
$badging = & $aapt dump badging $apk 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw 'APK identity verification failed.' }
if ($badging -notmatch "package: name='br.com.eyesproject.mobile.dev' versionCode='([0-9]+)' versionName='([^']+)'") {
    throw 'Expected the dev application identity.'
}
$versionCode = $Matches[1]
$versionName = $Matches[2]
if ($badging -match 'application-debuggable') { throw 'Expected a release-mode APK.' }
$pubspec = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'pubspec.yaml') -Raw
if ($pubspec -notmatch '(?m)^version:\s*([^+\s]+)\+([0-9]+)\s*$') { throw 'Invalid application version.' }
if ($versionName -ne ($Matches[1] + '-dev') -or $versionCode -ne $Matches[2]) { throw 'APK version differs from pubspec.' }
$flutterPin = Get-Content -LiteralPath (Join-Path $RepositoryRoot '.fvmrc') -Raw | ConvertFrom-Json
$apkName = "eyes-dev-release-$commit.apk"
$apkInfo = Get-Item -LiteralPath $apk
if ((GitValue @('rev-parse', 'HEAD')) -ne $commit -or (GitValue @('status', '--porcelain'))) {
    throw 'Source changed during packaging.'
}
if ((Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant() -ne $apkHash) {
    throw 'APK changed during verification.'
}
$metadata = [ordered]@{
    schema_version = 1
    generated_at = [DateTime]::UtcNow.ToString('o')
    source = @{ commit = $commit; clean = $true }
    ci = @{ run_id = $env:GITHUB_RUN_ID; attempt = $env:GITHUB_RUN_ATTEMPT; quality_gate = 'not_asserted_by_packaging' }
    apk = @{ file = $apkName; sha256 = $apkHash; size_bytes = $apkInfo.Length; application_id = 'br.com.eyesproject.mobile.dev'; version_name = $versionName; version_code = [int]$versionCode; build_mode = 'release'; flavor = 'dev'; signing = 'verified_test_key'; api_default = 'http://10.0.2.2:8080' }
    model = @{ id = $manifest.model_id; version = $manifest.model_version; sha256 = $manifest.artifact.sha256; size_bytes = $manifest.artifact.size_bytes; manifest_sha256 = (Sha256 $manifestBytes); embedded_assets_verified = $true }
    pinned_toolchains = @{ flutter = $flutterPin.flutter; java = 21 }
    limits = @('Test signature; not a store release.', 'No physical device/TalkBack/scientific acceptance asserted.', 'Requires the documented default dev API for account features; assistance remains offline.')
}
# Validate everything before creating the immutable output directory.
[IO.Directory]::CreateDirectory($output) | Out-Null
Copy-Item -LiteralPath $apk -Destination (Join-Path $output $apkName)
if ((Get-FileHash -LiteralPath (Join-Path $output $apkName) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $apkHash) {
    throw 'Copied APK differs from the verified artifact; package incomplete.'
}
[IO.File]::WriteAllText((Join-Path $output 'signature.txt'), $signature)
[IO.File]::WriteAllText((Join-Path $output 'demo-manifest.json'), ($metadata | ConvertTo-Json -Depth 8) + "`n")
$lines = @("$($metadata.apk.sha256)  $apkName")
foreach ($name in @('demo-manifest.json', 'signature.txt')) {
    $hash = (Get-FileHash -LiteralPath (Join-Path $output $name) -Algorithm SHA256).Hash.ToLowerInvariant()
    $lines += "$hash  $name"
}
[IO.File]::WriteAllText((Join-Path $output 'SHA256SUMS'), ($lines -join "`n") + "`n")
Write-Output "Verified dev release package for $commit; embedded model and signature checked."
