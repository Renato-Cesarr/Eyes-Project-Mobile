[CmdletBinding()]
param(
    [switch]$Ci
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$fvmConfig = Get-Content (Join-Path $repositoryRoot '.fvmrc') -Raw | ConvertFrom-Json
$expectedFlutter = $fvmConfig.flutter
$expectedJavaMajor = 21

function Fail([string]$Message) {
    throw "[toolchain] $Message"
}

if ($Ci) {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Fail 'Flutter não encontrado na CI.'
    }
    $flutterOutput = (& flutter --version | Out-String)
} else {
    if (Get-Command fvm -ErrorAction SilentlyContinue) {
        $flutterOutput = (& fvm flutter --version | Out-String)
    } else {
        $fvmExecutable = if ($env:LOCALAPPDATA) {
            Join-Path $env:LOCALAPPDATA 'Pub\Cache\bin\fvm.bat'
        } else {
            $null
        }
        if ($fvmExecutable -and (Test-Path $fvmExecutable)) {
            $flutterOutput = (& $fvmExecutable flutter --version | Out-String)
        } else {
            Fail 'FVM não encontrado. Instale a versão documentada no README.'
        }
    }
}

if ($flutterOutput -notmatch "Flutter $([regex]::Escape($expectedFlutter))") {
    Fail "Flutter $expectedFlutter é obrigatório."
}

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Fail 'Java não encontrado no PATH. Configure um JDK 21.'
}
$javaOutput = (& java -version 2>&1 | Out-String)
if ($javaOutput -notmatch 'version "(?<major>\d+)') {
    Fail 'Não foi possível identificar a versão do Java.'
}
if ([int]$Matches.major -ne $expectedJavaMajor) {
    Fail "Java $expectedJavaMajor é obrigatório; encontrado: $($Matches.major)."
}

$declaredJava = (Get-Content (Join-Path $repositoryRoot '.java-version') -Raw).Trim()
if ($declaredJava -ne "$expectedJavaMajor") {
    Fail ".java-version deve declarar $expectedJavaMajor."
}

Write-Host "[toolchain] OK - Flutter $expectedFlutter e Java $expectedJavaMajor."
