param(
    [switch]$NoBrowser,
    [switch]$CheckOnly
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir "start_demo.ps1"

if (-not (Test-Path -LiteralPath $target)) {
    throw "Missing script: $target"
}

& $target @PSBoundParameters
