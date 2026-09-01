param(
    [string]$DatabaseUrl = $env:DATABASE_URL,
    [string]$DatabaseUsername = $env:DATABASE_USERNAME,
    [string]$DatabasePassword = $env:DATABASE_PASSWORD,
    [string]$JwtSecret = $env:APP_JWT_SECRET,
    [string]$AllowedOrigins = $env:APP_CORS_ALLOWED_ORIGIN_PATTERNS
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
    throw "Missing DATABASE_URL. Example: jdbc:postgresql://your-host:5432/community_micro_logistics?sslmode=require"
}
if ([string]::IsNullOrWhiteSpace($DatabaseUsername)) {
    throw "Missing DATABASE_USERNAME."
}
if ([string]::IsNullOrWhiteSpace($DatabasePassword)) {
    throw "Missing DATABASE_PASSWORD."
}
if ([string]::IsNullOrWhiteSpace($JwtSecret)) {
    throw "Missing APP_JWT_SECRET. Use a random secret with at least 32 characters."
}
if ([string]::IsNullOrWhiteSpace($AllowedOrigins)) {
    throw "Missing APP_CORS_ALLOWED_ORIGIN_PATTERNS."
}

$env:SPRING_PROFILES_ACTIVE = "prod,seed"
$env:DATABASE_URL = $DatabaseUrl
$env:DATABASE_USERNAME = $DatabaseUsername
$env:DATABASE_PASSWORD = $DatabasePassword
$env:APP_JWT_SECRET = $JwtSecret
$env:APP_CORS_ALLOWED_ORIGIN_PATTERNS = $AllowedOrigins

Write-Host "Seeding cloud PostgreSQL with profile: $env:SPRING_PROFILES_ACTIVE"
Write-Host "Target: $DatabaseUrl"

& .\gradlew.bat bootRun

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
