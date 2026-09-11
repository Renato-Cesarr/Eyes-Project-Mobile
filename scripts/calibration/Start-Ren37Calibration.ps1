[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$')]
    [string]$SessionId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$')]
    [string]$ScenarioId,

    [Parameter(Mandatory = $true)]
    [ValidateSet('calibration', 'evaluation')]
    [string]$DatasetSplit,

    [Parameter(Mandatory = $true)]
    [ValidateSet('person', 'chair', 'table', 'backpack')]
    [string]$ExpectedKind,

    [Parameter(Mandatory = $true)]
    [ValidateSet('distant', 'attention', 'veryNear')]
    [string]$ExpectedBand,

    [Parameter(Mandatory = $true)]
    [ValidateSet('bright', 'dim', 'backlit')]
    [string]$Lighting,

    [Parameter(Mandatory = $true)]
    [ValidateSet('none', 'partial')]
    [string]$Occlusion,

    [string]$Serial,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$artifactDirectory = Join-Path $repositoryRoot 'artifacts\calibration'
$apkPath = Join-Path $repositoryRoot 'build\app\outputs\flutter-apk\app-dev-profile.apk'
$component = 'br.com.eyesproject.mobile.dev/br.com.eyesproject.mobile.MainActivity'

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $serialArguments = if ($Serial) { @('-s', $Serial) } else { @() }
    & adb @serialArguments @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ADB falhou: adb $($Arguments -join ' ')"
    }
}

function Convert-BatterySnapshot {
    param([string]$Raw)
    $level = [regex]::Match($Raw, '(?m)^\s*level:\s*(\d+)')
    $temperature = [regex]::Match($Raw, '(?m)^\s*temperature:\s*(\d+)')
    $status = [regex]::Match($Raw, '(?m)^\s*status:\s*(\d+)')
    return [ordered]@{
        levelPercent = if ($level.Success) { [int]$level.Groups[1].Value } else { $null }
        temperatureCelsius = if ($temperature.Success) { [math]::Round(([int]$temperature.Groups[1].Value) / 10, 1) } else { $null }
        androidStatusCode = if ($status.Success) { [int]$status.Groups[1].Value } else { $null }
    }
}

$onlineDevices = @(
    & adb devices | Select-String "`tdevice$" | ForEach-Object {
        ($_ -split "`t")[0]
    }
)
if ($Serial) {
    if ($onlineDevices -notcontains $Serial) {
        throw "O dispositivo '$Serial' não está autorizado no ADB."
    }
} elseif ($onlineDevices.Count -ne 1) {
    throw "É necessário exatamente um aparelho autorizado no ADB ou informar -Serial. Encontrados: $($onlineDevices.Count)."
} else {
    $Serial = $onlineDevices[0]
}

if (-not $SkipBuild) {
    Push-Location $repositoryRoot
    try {
        & flutter build apk --profile --flavor dev --target lib/main_dev.dart --dart-define=EYES_CALIBRATION=true
        if ($LASTEXITCODE -ne 0) {
            throw 'O build Profile de calibração falhou.'
        }
    } finally {
        Pop-Location
    }
}
if (-not (Test-Path -LiteralPath $apkPath)) {
    throw "APK de calibração não encontrado em '$apkPath'."
}

New-Item -ItemType Directory -Force -Path $artifactDirectory | Out-Null
$metadataPath = Join-Path $artifactDirectory "$SessionId.start.json"
$rawLogPath = Join-Path $artifactDirectory "$SessionId.logcat.tmp"
$errorLogPath = Join-Path $artifactDirectory "$SessionId.logcat-error.tmp"
Invoke-Adb install -r $apkPath | Out-Null
$batteryStartRaw = Invoke-Adb shell dumpsys battery | Out-String
$adbExecutable = (Get-Command adb -ErrorAction Stop).Source
Invoke-Adb logcat -c | Out-Null
$logcatArguments = @('-s', $Serial, 'logcat', '-v', 'raw', 'flutter:I', '*:S')
$logcatProcess = Start-Process `
    -FilePath $adbExecutable `
    -ArgumentList $logcatArguments `
    -RedirectStandardOutput $rawLogPath `
    -RedirectStandardError $errorLogPath `
    -WindowStyle Hidden `
    -PassThru
$metadata = [ordered]@{
    schemaVersion = 1
    sessionId = $SessionId
    scenarioId = $ScenarioId
    startedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    serial = $Serial
    model = (Invoke-Adb shell getprop ro.product.model | Out-String).Trim()
    androidVersion = (Invoke-Adb shell getprop ro.build.version.release | Out-String).Trim()
    androidApi = (Invoke-Adb shell getprop ro.build.version.sdk | Out-String).Trim()
    batteryStart = Convert-BatterySnapshot $batteryStartRaw
    logcatProcessId = $logcatProcess.Id
}
$metadata | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $metadataPath -Encoding utf8

Invoke-Adb shell am start -S -n $component `
    --ez calibrationEnabled true `
    --es calibrationSessionId $SessionId `
    --es calibrationScenarioId $ScenarioId `
    --es calibrationDatasetSplit $DatasetSplit `
    --es calibrationExpectedKind $ExpectedKind `
    --es calibrationExpectedBand $ExpectedBand `
    --es calibrationLighting $Lighting `
    --es calibrationOcclusion $Occlusion | Out-Null

Write-Host "Sessão REN-37 iniciada no aparelho $Serial."
Write-Host "Execute o cenário '$ScenarioId' e mantenha a varredura ativa pelo tempo definido no protocolo."
Write-Host "Ao concluir, rode scripts/calibration/Stop-Ren37Calibration.ps1 -SessionId '$SessionId' -Serial '$Serial'."
