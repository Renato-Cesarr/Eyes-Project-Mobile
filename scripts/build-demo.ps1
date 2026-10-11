[CmdletBinding()]
param(
    [string]$ApiBaseUrl = 'http://10.0.2.2:8080'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'demo-build-receipt.ps1')
Assert-DemoApiUrl $ApiBaseUrl
$repositoryRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
function GitValue([string[]]$Arguments) {
    $result = & git -C $repositoryRoot @Arguments
    if ($LASTEXITCODE -ne 0) { throw 'Git verification failed.' }
    return ($result | Out-String).Trim()
}
function Invoke-Flutter([string[]]$Arguments) {
    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) { throw 'Flutter demonstration build failed; no build receipt created.' }
}
$commit = GitValue @('rev-parse', 'HEAD')
if ($commit -notmatch '^[a-f0-9]{40}$' -or (GitValue @('status', '--porcelain'))) {
    throw 'Demo build requires a clean Git checkout with a fixed commit.'
}
Push-Location $repositoryRoot
try {
    & (Join-Path $PSScriptRoot 'check-toolchain.ps1') -Ci
    Invoke-Flutter @('clean')
    Invoke-Flutter @('pub', 'get')
    Invoke-Flutter @('build', 'apk', '--release', '--flavor', 'dev', '--target', 'lib/main_dev.dart', "--dart-define=API_BASE_URL=$ApiBaseUrl")
    if ((GitValue @('rev-parse', 'HEAD')) -cne $commit -or (GitValue @('status', '--porcelain'))) {
        throw 'Source changed during the demonstration build; no build receipt created.'
    }
    $apkPath = Join-Path $repositoryRoot 'build/app/outputs/flutter-apk/app-dev-release.apk'
    $apk = Get-Item -LiteralPath $apkPath
    $pin = Get-Content -LiteralPath (Join-Path $repositoryRoot '.fvmrc') -Raw | ConvertFrom-Json
    $receipt = [ordered]@{
        schema_version = 1
        generated_at = [DateTime]::UtcNow.ToString('o')
        source = @{ commit = $commit; clean = $true }
        build = @{ clean = $true; mode = 'release'; flavor = 'dev'; target = 'lib/main_dev.dart'; api_base_url = $ApiBaseUrl }
        toolchains = @{ flutter = $pin.flutter; java = 21 }
        apk = @{ sha256 = (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash.ToLowerInvariant(); size_bytes = $apk.Length }
    }
    $receiptPath = Join-Path $repositoryRoot 'build/demo-build-receipt.json'
    [IO.File]::WriteAllText($receiptPath, ($receipt | ConvertTo-Json -Depth 8) + "`n")
    Write-Output "Clean demonstration build recorded for $commit."
} finally { Pop-Location }
