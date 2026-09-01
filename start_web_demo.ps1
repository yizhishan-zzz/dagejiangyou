param(
    [switch]$NoBrowser,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $projectRoot "backend"
$frontendDir = Join-Path $projectRoot "frontend"
$webDir = Join-Path $frontendDir "build\web"
$backendPort = 8080
$frontendPort = 4100
$frontendUrl = "http://127.0.0.1:$frontendPort"
$backendApiUrl = "http://127.0.0.1:$backendPort/api/v1"

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "==== $Text ====" -ForegroundColor Cyan
}

function Get-PortOwnerInfo {
    param([int]$Port)

    try {
        $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
            Select-Object -First 1
        if (-not $connection) {
            return $null
        }

        $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
        $processName = if ($process) { $process.ProcessName } else { "Unknown" }
        return [pscustomobject]@{
            Port = $Port
            Pid = $connection.OwningProcess
            ProcessName = $processName
        }
    }
    catch {
        return $null
    }
}

function Wait-ForPort {
    param(
        [int]$Port,
        [int]$TimeoutSeconds = 150
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Get-PortOwnerInfo -Port $Port) {
            return $true
        }
        Start-Sleep -Seconds 1
    }

    return $false
}

function Wait-ForBackendHealth {
    param(
        [int]$TimeoutSeconds = 180
    )

    $healthUrl = "http://127.0.0.1:$backendPort/actuator/health"
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastError = $null

    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 3
            if ($response.status -eq "UP") {
                return $true
            }
            $lastError = "Health status: $($response.status)"
        }
        catch {
            $lastError = $_.Exception.Message
        }
        Start-Sleep -Seconds 2
    }

    if ($lastError) {
        Write-Host "Last backend health check: $lastError" -ForegroundColor Yellow
    }
    return $false
}

function Test-FrontendReady {
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $frontendUrl -Method Get -TimeoutSec 5
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

function Wait-ForFrontendReady {
    param(
        [int]$TimeoutSeconds = 30
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-FrontendReady) {
            return $true
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Resolve-PythonCommand {
    $candidates = @(
        (Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        (Get-Command py.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -ErrorAction SilentlyContinue) }

    return $candidates | Select-Object -First 1
}

function Resolve-BrowserCommand {
    $candidates = @(
        (Get-Command msedge.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        (Get-Command chrome.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -ErrorAction SilentlyContinue) }

    return $candidates | Select-Object -First 1
}

function Start-ToolWindow {
    param(
        [string]$Title,
        [string]$WorkingDirectory,
        [string]$CommandText
    )

    $titleLiteral = "'" + $Title.Replace("'", "''") + "'"
    $workdirLiteral = "'" + $WorkingDirectory.Replace("'", "''") + "'"
    $psCommand = "`$Host.UI.RawUI.WindowTitle = $titleLiteral; Set-Location -LiteralPath $workdirLiteral; $CommandText"

    Start-Process -FilePath "powershell.exe" `
        -WorkingDirectory $WorkingDirectory `
        -ArgumentList @(
            "-NoExit",
            "-ExecutionPolicy", "Bypass",
            "-Command", $psCommand
        ) `
        -WindowStyle Normal | Out-Null
}

Write-Section "Environment Check"

if (-not (Test-Path -LiteralPath $backendDir)) {
    throw "Missing backend folder: $backendDir"
}

if (-not (Test-Path -LiteralPath $frontendDir)) {
    throw "Missing frontend folder: $frontendDir"
}

if (-not (Test-Path -LiteralPath (Join-Path $backendDir "gradlew.bat"))) {
    throw "Missing Gradle wrapper: $backendDir\gradlew.bat"
}

if (-not (Test-Path -LiteralPath (Join-Path $webDir "index.html"))) {
    throw "Missing built web app: $webDir\index.html. Run 'flutter build web --release' first."
}

$pythonCommand = Resolve-PythonCommand
if (-not $pythonCommand) {
    throw "Python was not found. Install Python 3 to host the built web app."
}

$backendPortInfo = Get-PortOwnerInfo -Port $backendPort
$frontendPortInfo = Get-PortOwnerInfo -Port $frontendPort

Write-Host "Backend folder: $backendDir"
Write-Host "Frontend folder: $frontendDir"
Write-Host "Web build folder: $webDir"
Write-Host "Backend API: $backendApiUrl"
Write-Host "Frontend URL: $frontendUrl"
Write-Host "Static server: $pythonCommand"

Write-Section "Demo Accounts"
Write-Host "Creator: 13800000001 / demo123456"
Write-Host "Runner:  13800000002 / demo123456"
Write-Host "Neighbor:13800000003 / demo123456"

if ($CheckOnly) {
    Write-Section "Done"
    Write-Host "Check only mode. No services were started."
    exit 0
}

Write-Section "Starting Services"

if (-not $backendPortInfo) {
    Start-ToolWindow `
        -Title "Micro Logistics Backend (dev)" `
        -WorkingDirectory $backendDir `
        -CommandText "& .\gradlew.bat bootRun --args='--spring.profiles.active=dev'"
    Write-Host "Backend window started."
}
else {
    Write-Host "Backend port $backendPort is already occupied. Checking application health..." -ForegroundColor Yellow
}

Write-Section "Waiting For Backend"
if (-not (Wait-ForBackendHealth -TimeoutSeconds 180)) {
    throw "Backend did not become healthy in time. Please check the backend window and database configuration."
}
Write-Host "Backend is healthy at http://127.0.0.1:$backendPort" -ForegroundColor Green

if (-not $frontendPortInfo) {
    Start-ToolWindow `
        -Title "Micro Logistics Web (static)" `
        -WorkingDirectory $webDir `
        -CommandText "& '$pythonCommand' -m http.server $frontendPort --bind 127.0.0.1 --directory ."
    Write-Host "Static web server window started."
}
else {
    Write-Host "Frontend port $frontendPort is already occupied. Checking page availability..." -ForegroundColor Yellow
}

Write-Section "Waiting For Frontend"
if (-not (Wait-ForFrontendReady -TimeoutSeconds 30)) {
    throw "Frontend did not become ready in time. Please check the frontend window."
}

Write-Host "Frontend is ready at $frontendUrl" -ForegroundColor Green

if (-not $NoBrowser) {
    $browserCommand = Resolve-BrowserCommand
    if ($browserCommand) {
        Start-Process -FilePath $browserCommand -ArgumentList @("--new-window", $frontendUrl) | Out-Null
    }
    else {
        Start-Process $frontendUrl
    }
}

Write-Section "Suggested Flow"
Write-Host "1. Open the web page. Password login is the default tab."
Write-Host "2. Enter a test account, or use the one-click fill buttons."
Write-Host "3. Show creator login and task publishing first."
Write-Host "4. Logout, switch to runner account, then accept the task."
Write-Host "5. Use OTP login only if you want to show the SMS-style flow."
