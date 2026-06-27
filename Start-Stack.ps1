# ==========================================
# ENVIRONMENT CONFIGURATION (DYNAMIC PATHS)
# ==========================================
$WorkingDir = $PSScriptRoot
Set-Location $WorkingDir

# Define isolated subdirectories
$LogDir = "$WorkingDir\log"
$TmpDir = "$WorkingDir\tmp"

# Automatically ensure directories exist before launching
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
if (-not (Test-Path $TmpDir)) { New-Item -ItemType Directory -Path $TmpDir | Out-Null }

# Re-route Log and PID configurations to their designated targets
$PhoenixLog    = "$LogDir\phoenix.log"
$PhoenixErrLog = "$LogDir\phoenix.err"
$LiteLLMLog    = "$LogDir\litellm.log"
$LiteLLMErrLog = "$LogDir\litellm.err"

$PhoenixPidFile = "$TmpDir\phoenix.pid"
$LiteLLMPidFile = "$TmpDir\litellm.pid"

# Set network environment bypass variables
$env:NO_PROXY="127.0.0.1,localhost"
$env:no_proxy="127.0.0.1,localhost"
$env:PHOENIX_COLLECTOR_ENDPOINT="http://127.0.0.1:6006/v1/traces"
$env:OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:6006"
$env:OTEL_EXPORTER_OTLP_TRACES_PROTOCOL="http/json"
$env:PRISMA_CLI_BINARY_TARGETS="native"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " STARTING AI DEVELOPMENT STACK (BACKGROUND MODE) " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Clean up stale pid/error structures inside our subfolders
Remove-Item $PhoenixPidFile, $LiteLLMPidFile, $PhoenixErrLog, $LiteLLMErrLog -ErrorAction SilentlyContinue

# ==========================================
# 1. LAUNCH ARIZE PHOENIX
# ==========================================
Write-Host "Launching Arize Phoenix on port 6006..." -ForegroundColor Yellow

$PhoenixProcess = Start-Process -FilePath "python" -ArgumentList "-m phoenix.server.main launch" `
    -NoNewWindow -PassThru `
    -RedirectStandardOutput $PhoenixLog `
    -RedirectStandardError $PhoenixErrLog

if ($PhoenixProcess) {
    $PhoenixProcess.Id | Out-File -FilePath $PhoenixPidFile -Encoding ascii
    Write-Host "✔ Phoenix started successfully. PID: $($PhoenixProcess.Id)" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to start Phoenix." -ForegroundColor Red
}

# Brief pause to let Phoenix claim its socket before LiteLLM binds
Start-Sleep -Seconds 2

# ==========================================
# 2. LAUNCH LITELLM PROXY
# ==========================================
Write-Host "Launching LiteLLM Proxy on port 4000..." -ForegroundColor Yellow

$LiteLLMProcess = Start-Process -FilePath "litellm" -ArgumentList "--config config.yaml --host 127.0.0.1 --port 4000 --detailed_debug" `
    -NoNewWindow -PassThru `
    -RedirectStandardOutput $LiteLLMLog `
    -RedirectStandardError $LiteLLMErrLog

if ($LiteLLMProcess) {
    $LiteLLMProcess.Id | Out-File -FilePath $LiteLLMPidFile -Encoding ascii
    Write-Host "✔ LiteLLM Proxy started successfully. PID: $($LiteLLMProcess.Id)" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to start LiteLLM Proxy." -ForegroundColor Red
}

# ==========================================
# 3. SELF-DESTRUCT ORCHESTRATOR WINDOW
# ==========================================
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "All processes are running silently in the background." -ForegroundColor White
Write-Host "Outputs are structured under \log and \tmp subfolders." -ForegroundColor White

for ($i = 5; $i -gt 0; $i--) {
    Write-Host "`rThis orchestrator console will close automatically in $i seconds... " -NoNewline -ForegroundColor Gray
    Start-Sleep -Seconds 1
}

Exit