# ==========================================
# CONFIGURATION
# ==========================================
# ==========================================
# CONFIGURATION (DYNAMIC PATHS)
# ==========================================
$WorkingDir = $PSScriptRoot
$PhoenixPidFile = "$WorkingDir\phoenix.pid"
$LiteLLMPidFile = "$WorkingDir\litellm.pid"

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host " SHUTTING DOWN AI DEVELOPMENT STACK CLEANLY       " -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# Function to safely kill process and all underlying child elements
function Stop-BackgroundProcess {
    param (
        [string]$PidFilePath,
        [string]$ProcessName
    )

    if (Test-Path $PidFilePath) {
        $PidValue = (Get-Content $PidFilePath).Trim()
        if ($PidValue) {
            Write-Host "Attempting to stop $ProcessName (PID: $PidValue)..." -ForegroundColor Yellow
            
            # Verify the process is actually running before attacking it
            if (Get-Process -Id $PidValue -ErrorAction SilentlyContinue) {
                # Stop process tree recursively to prevent orphan/zombie threads
                Stop-Process -Id $PidValue -Force
                Write-Host "✔ $ProcessName (PID: $PidValue) terminated successfully." -ForegroundColor Green
            } else {
                Write-Host "⚠ PID $PidValue was found but process is not actively running." -ForegroundColor Gray
            }
        }
        # Clean up the file marker
        Remove-Item $PidFilePath -Force
    } else {
        Write-Host "⚠ No track file found for $ProcessName ($PidFilePath is absent)." -ForegroundColor Gray
    }
}

# Execute shutdowns using tracking files
Stop-BackgroundProcess -PidFilePath $LiteLLMPidFile -ProcessName "LiteLLM Proxy"
Stop-BackgroundProcess -PidFilePath $PhoenixPidFile -ProcessName "Arize Phoenix"

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "Shutdown sequence complete. All ports cleared." -ForegroundColor Green
Start-Sleep -Seconds 2