# ==========================================
# CONFIGURATION (DYNAMIC PATHS)
# ==========================================
$WorkingDir = $PSScriptRoot
$LogDir = "$WorkingDir\log"
$TmpDir = "$WorkingDir\tmp"

$PhoenixPidFile = "$TmpDir\phoenix.pid"
$LiteLLMPidFile = "$TmpDir\litellm.pid"

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
            Write-Host "Attempting to stop $ProcessName (PID tree: $PidValue)..." -ForegroundColor Yellow
            
            # Verify the wrapper process is active before executing a teardown
            if (Get-Process -Id $PidValue -ErrorAction SilentlyContinue) {
                # Use taskkill with tree (/T) and force (/F) flags to clean up both cmd and spawned child engine runtimes
                taskkill /PID $PidValue /T /F | Out-Null
                Write-Host "✔ $ProcessName process tree terminated successfully." -ForegroundColor Green
            } else {
                Write-Host "⚠ PID $PidValue was found but process tree is not actively running." -ForegroundColor Gray
            }
        }
        # Clean up the file marker
        Remove-Item $PidFilePath -Force
    } else {
        Write-Host "⚠ No track file found for $ProcessName ($PidFilePath is absent)." -ForegroundColor Gray
    }
}

# Execute shutdowns using tracking files matching new path metrics
Stop-BackgroundProcess -PidFilePath $LiteLLMPidFile -ProcessName "LiteLLM Proxy"
Stop-BackgroundProcess -PidFilePath $PhoenixPidFile -ProcessName "Arize Phoenix"

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "Shutdown sequence complete. All ports cleared." -ForegroundColor Green
Start-Sleep -Seconds 2