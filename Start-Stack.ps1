# ==========================================
# ENVIRONMENT CONFIGURATION
# ==========================================

# ==========================================
# ENVIRONMENT CONFIGURATION (DYNAMIC PATHS)
# ==========================================
# Automatically maps to whatever folder this script is sitting in
$WorkingDir = $PSScriptRoot
Set-Location $WorkingDir

# Define Log and PID paths relative to the script location
$PhoenixLog = "$WorkingDir\phoenix.log"
$LiteLLMLog = "$WorkingDir\litellm.log"
$PhoenixPidFile = "$WorkingDir\phoenix.pid"
$LiteLLMPidFile = "$WorkingDir\litellm.pid"

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

# Clear out any old PID files from previous unclean runs
Remove-Item $PhoenixPidFile, $LiteLLMPidFile -ErrorAction SilentlyContinue

# ==========================================
# 1. LAUNCH ARIZE PHOENIX
# ==========================================
Write-Host "Launching Arize Phoenix on port 6006..." -ForegroundColor Yellow
# Adjust 'arize-phoenix start' to your exact global launch syntax if needed (e.g., 'python -m phoenix.server.main launch')
$PhoenixProcess = Start-Process -FilePath "python" -ArgumentList "-m phoenix.server.main launch" `
    -NoNewWindow -PassThru `
    -RedirectStandardOutput $PhoenixLog `
    -RedirectStandardError $PhoenixLog

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
    -RedirectStandardError $LiteLLMLog

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
Write-Host "Logs are being captured in separate .log files." -ForegroundColor White

for ($i = 5; $i -gt 0; $i--) {
    Write-Host "`rThis orchestrator console will close automatically in $i seconds... " -NoNewline -ForegroundColor Gray
    Start-Sleep -Seconds 1
}

Exit