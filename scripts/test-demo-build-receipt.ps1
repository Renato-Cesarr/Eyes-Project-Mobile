$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'demo-build-receipt.ps1')
$testDirectory = Join-Path ([IO.Path]::GetTempPath()) ('eyes-demo-receipt-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testDirectory) | Out-Null
$apkPath = Join-Path $testDirectory 'candidate.apk'
$receiptPath = Join-Path $testDirectory 'receipt.json'
[IO.File]::WriteAllText($apkPath, 'first compiled artifact')
$commit = 'a' * 40
function New-Receipt {
    return @{
        schema_version = 1
        source = @{ commit = $commit; clean = $true }
        build = @{ clean = $true; mode = 'release'; flavor = 'dev'; target = 'lib/main_dev.dart'; api_base_url = 'http://10.0.2.2:8080' }
        toolchains = @{ flutter = '3.44.0'; java = 21 }
        apk = @{ sha256 = (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash.ToLowerInvariant(); size_bytes = (Get-Item -LiteralPath $apkPath).Length }
    }
}
function Save-Receipt($Value) {
    [IO.File]::WriteAllText($receiptPath, ($Value | ConvertTo-Json -Depth 8))
}
function Verify([string]$ExpectedApi = 'http://10.0.2.2:8080') {
    Get-VerifiedDemoBuildReceipt -ReceiptPath $receiptPath -ApkPath $apkPath -Commit $commit -FlutterVersion '3.44.0' -ExpectedApiBaseUrl $ExpectedApi | Out-Null
}
$passed = 0
function Reject([string]$Name, [scriptblock]$Operation, [string]$ExpectedError) {
    $caught = $null
    try { & $Operation } catch { $caught = $_.Exception.Message }
    if (-not $caught -or $caught -notmatch $ExpectedError) { throw "Failed rejection scenario: $Name" }
    $script:passed++
    Write-Output "PASS $Name"
}
try {
    Reject 'APK without build receipt' { Verify } 'Build receipt missing'
    Save-Receipt (New-Receipt)
    Verify
    $passed++
    Write-Output 'PASS valid matching artifact'
    [IO.File]::WriteAllText($apkPath, 'other compiled artifact')
    Reject 'replaced APK with same byte count' { Verify } 'APK differs'
    Save-Receipt (New-Receipt)
    $receipt = New-Receipt; $receipt.source.commit = 'b' * 40; Save-Receipt $receipt
    Reject 'old build from another commit' { Verify } 'this source commit'
    $receipt = New-Receipt; $receipt.source.clean = $false; Save-Receipt $receipt
    Reject 'dirty source build' { Verify } 'clean build'
    $receipt = New-Receipt; $receipt.build.clean = $false; Save-Receipt $receipt
    Reject 'incremental build receipt' { Verify } 'clean build'
    $receipt = New-Receipt; $receipt.build.api_base_url = 'http://127.0.0.1:8080'; Save-Receipt $receipt
    Reject 'USB APK mislabeled as emulator APK' { Verify } 'Build API differs'
    Verify 'http://127.0.0.1:8080'
    $passed++
    Write-Output 'PASS explicitly selected USB configuration'
    foreach ($url in @('http://user:secret@localhost:8080', 'https://localhost/?token=secret', 'file:///tmp/api')) {
        Reject 'unsafe API configuration' { Assert-DemoApiUrl $url } 'absolute HTTP'
    }
    $receipt = New-Receipt; $receipt.toolchains.flutter = '0.0.0'; Save-Receipt $receipt
    Reject 'unrecognized compiler version' { Verify } 'unexpected build configuration'
    $receipt = New-Receipt; $receipt.build.target = 'lib/main_prod.dart'; Save-Receipt $receipt
    Reject 'production entrypoint' { Verify } 'unexpected build configuration'
    $receipt = New-Receipt; $receipt.schema_version = 99; Save-Receipt $receipt
    Reject 'unknown receipt schema' { Verify } 'this source commit'
    [IO.File]::WriteAllText($receiptPath, '{}')
    Reject 'incomplete receipt' { Verify } 'schema_version'
    Write-Output "$passed receipt checks passed."
} finally {
    # Only the literal, freshly created directory beneath the system temp root.
    $resolved = (Resolve-Path -LiteralPath $testDirectory).Path
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected temporary test path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
