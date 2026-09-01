param(
    [switch]$NoBrowser,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$scriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "start_web_demo.ps1"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Missing launcher: $scriptPath"
}

$arguments = @()
if ($NoBrowser) { $arguments += "-NoBrowser" }
if ($CheckOnly) { $arguments += "-CheckOnly" }

& powershell.exe -ExecutionPolicy Bypass -File $scriptPath @arguments
exit $LASTEXITCODE
