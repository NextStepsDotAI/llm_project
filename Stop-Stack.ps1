# ==========================================
# CONFIGURATION (DYNAMIC PATHS)
# ==========================================
$WorkingDir = $PSScriptRoot
$LogDir = "$WorkingDir\log"
$TmpDir = "$WorkingDir\tmp"

$PhoenixPidFile = "$TmpDir\phoenix.pid"
$LiteLLMPidFile = "$TmpDir\litellm.pid"
$PhoenixErrLog  = "$LogDir\phoenix.err"
$LiteLLMErrLog  = "$LogDir\litellm.err"

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host " SHUTTING DOWN AI DEVELOPMENT STACK CLEANLY       " -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# Function to safely kill process and all underlying child elements
function Stop-BackgroundProcess {
    param (
        [string]$PidFilePath,
        [string]$ProcessName,
        [string]$ErrLogPath
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

    # Clean up the runtime error log file if it exists inside the log folder
    if (Test-Path $ErrLogPath) {
        Remove-Item $ErrLogPath -Force
    }
}

# Execute shutdowns using tracking files matching new path metrics
Stop-BackgroundProcess -PidFilePath $LiteLLMPidFile -ProcessName "LiteLLM Proxy" -ErrLogPath $LiteLLMErrLog
Stop-BackgroundProcess -PidFilePath $PhoenixPidFile -ProcessName "Arize Phoenix" -ErrLogPath $PhoenixErrLog

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "Shutdown sequence complete. All ports cleared." -ForegroundColor Green
Start-Sleep -Seconds 2