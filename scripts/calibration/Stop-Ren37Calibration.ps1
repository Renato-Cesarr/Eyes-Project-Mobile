[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$')]
    [string]$SessionId,
    [string]$Serial
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$artifactDirectory = Join-Path $repositoryRoot 'artifacts\calibration'
$startPath = Join-Path $artifactDirectory "$SessionId.start.json"
$jsonlPath = Join-Path $artifactDirectory "$SessionId.jsonl"
$devicePath = Join-Path $artifactDirectory "$SessionId.device.json"
$rawLogPath = Join-Path $artifactDirectory "$SessionId.logcat.tmp"
$errorLogPath = Join-Path $artifactDirectory "$SessionId.logcat-error.tmp"
$marker = 'EYES_CALIBRATION|'
$package = 'br.com.eyesproject.mobile.dev'

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

if (-not (Test-Path -LiteralPath $startPath)) {
    throw "Metadados iniciais não encontrados: '$startPath'."
}
$startMetadata = Get-Content -Raw -LiteralPath $startPath | ConvertFrom-Json
if (-not $Serial) {
    $Serial = $startMetadata.serial
}

$logcatProcess = Get-Process -Id $startMetadata.logcatProcessId -ErrorAction SilentlyContinue
if ($logcatProcess) {
    if ($logcatProcess.ProcessName -ne 'adb') {
        throw "O processo de coleta registrado não é o ADB; cancelando encerramento seguro."
    }
    Stop-Process -Id $logcatProcess.Id
    Wait-Process -Id $logcatProcess.Id -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 500

$validEvents = [System.Collections.Generic.List[string]]::new()
$rawLog = if (Test-Path -LiteralPath $rawLogPath) {
    Get-Content -LiteralPath $rawLogPath
} else {
    Invoke-Adb logcat -d -v raw
}
foreach ($line in $rawLog) {
    $markerIndex = $line.IndexOf($marker, [System.StringComparison]::Ordinal)
    if ($markerIndex -lt 0) {
        continue
    }
    $json = $line.Substring($markerIndex + $marker.Length).Trim()
    try {
        $null = $json | ConvertFrom-Json
        $validEvents.Add($json)
    } catch {
        Write-Warning 'Uma linha de telemetria truncada ou inválida foi ignorada.'
    }
}
if ($validEvents.Count -eq 0) {
    throw 'Nenhum evento EYES_CALIBRATION foi encontrado. Confirme que o APK foi compilado com EYES_CALIBRATION=true e que a varredura foi iniciada.'
}
$validEvents | Set-Content -LiteralPath $jsonlPath -Encoding utf8

$batteryEndRaw = Invoke-Adb shell dumpsys battery | Out-String
$thermalEnd = Invoke-Adb shell dumpsys thermalservice | Out-String
$memoryEnd = Invoke-Adb shell dumpsys meminfo $package | Out-String
$crashLog = Invoke-Adb logcat -d -b crash -v brief | Out-String
$eventsLog = Invoke-Adb logcat -d -b events -v brief | Out-String
$thermalStatusMatch = [regex]::Match($thermalEnd, '(?im)Thermal Status:\s*(\d+)')
$totalPssMatch = [regex]::Match($memoryEnd, '(?im)TOTAL PSS:\s*(\d+)')
$totalRssMatch = [regex]::Match($memoryEnd, '(?im)TOTAL RSS:\s*(\d+)')
$device = [ordered]@{
    schemaVersion = 1
    sessionId = $SessionId
    scenarioId = $startMetadata.scenarioId
    startedAtUtc = $startMetadata.startedAtUtc
    endedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    serial = $Serial
    model = $startMetadata.model
    androidVersion = $startMetadata.androidVersion
    androidApi = $startMetadata.androidApi
    batteryStart = $startMetadata.batteryStart
    batteryEnd = Convert-BatterySnapshot $batteryEndRaw
    thermalStatus = if ($thermalStatusMatch.Success) { [int]$thermalStatusMatch.Groups[1].Value } else { $null }
    totalPssKb = if ($totalPssMatch.Success) { [int]$totalPssMatch.Groups[1].Value } else { $null }
    totalRssKb = if ($totalRssMatch.Success) { [int]$totalRssMatch.Groups[1].Value } else { $null }
    fatalExceptionCount = ([regex]::Matches($crashLog, 'FATAL EXCEPTION')).Count
    anrCount = ([regex]::Matches($eventsLog, "am_anr.*$([regex]::Escape($package))")).Count
    calibrationEventCount = $validEvents.Count
}
$device | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $devicePath -Encoding utf8
Invoke-Adb shell am force-stop $package | Out-Null
Remove-Item -LiteralPath $rawLogPath, $errorLogPath -Force -ErrorAction SilentlyContinue

Write-Host "Coleta salva em: $jsonlPath"
Write-Host "Métricas do aparelho salvas em: $devicePath"
Write-Host "Gere o relatório com: dart run tool/calibration_report.dart --input `"$jsonlPath`" --output `"docs/benchmarks/REN-37-$SessionId.md`" --device-metrics `"$devicePath`""
