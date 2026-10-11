Set-StrictMode -Version Latest

function Assert-DemoApiUrl([string]$Value) {
    $uri = $null
    if (-not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -notin @('http', 'https') -or -not $uri.Host -or
        $uri.UserInfo -or $uri.Query -or $uri.Fragment -or $Value -ne $Value.Trim()) {
        throw 'Demo API must be an absolute HTTP(S) URL without credentials, query or fragment.'
    }
}

function Get-VerifiedDemoBuildReceipt {
    param(
        [string]$ReceiptPath,
        [string]$ApkPath,
        [string]$Commit,
        [string]$FlutterVersion,
        [string]$ExpectedApiBaseUrl
    )
    Assert-DemoApiUrl $ExpectedApiBaseUrl
    if (-not (Test-Path -LiteralPath $ReceiptPath -PathType Leaf)) {
        throw 'Build receipt missing. Generate a fresh APK with scripts/build-demo.ps1.'
    }
    $receipt = Get-Content -LiteralPath $ReceiptPath -Raw | ConvertFrom-Json
    if ($receipt.schema_version -ne 1 -or $receipt.source.commit -cne $Commit -or
        $receipt.source.clean -isnot [bool] -or -not $receipt.source.clean -or
        $receipt.build.clean -isnot [bool] -or -not $receipt.build.clean) {
        throw 'Build receipt does not identify a clean build of this source commit.'
    }
    if ($receipt.build.mode -cne 'release' -or $receipt.build.flavor -cne 'dev' -or
        $receipt.build.target -cne 'lib/main_dev.dart' -or
        $receipt.toolchains.flutter -cne $FlutterVersion -or $receipt.toolchains.java -ne 21) {
        throw 'Build receipt has an unexpected build configuration or toolchain.'
    }
    Assert-DemoApiUrl $receipt.build.api_base_url
    if ($receipt.build.api_base_url -cne $ExpectedApiBaseUrl) {
        throw 'Build API differs from the explicitly expected demonstration API.'
    }
    $apk = Get-Item -LiteralPath $ApkPath
    $hash = (Get-FileHash -LiteralPath $ApkPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($receipt.apk.sha256 -cne $hash -or $receipt.apk.size_bytes -ne $apk.Length) {
        throw 'APK differs from the artifact produced by the recorded clean build.'
    }
    return $receipt
}
