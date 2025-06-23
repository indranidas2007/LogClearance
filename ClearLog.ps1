# Get the current script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define log file for script output in a "log" subfolder
$logSubDir = Join-Path $scriptDir "log"
if (!(Test-Path $logSubDir)) {
    New-Item -ItemType Directory -Path $logSubDir -Force
}
$logFile = Join-Path $logSubDir "log_cleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Read log paths from external text file
$logPathFile = Join-Path $scriptDir "log_paths.txt"
if (!(Test-Path $logPathFile)) {
    Write-Output "❌ Path file not found: $logPathFile" | Tee-Object -FilePath $logFile -Append
    exit
}

$logPaths = Get-Content $logPathFile | Where-Object { $_.Trim() -ne "" }

# Set age threshold
$daysOld = 10
$cutoffDate = (Get-Date).AddDays(-$daysOld)

# Process each path
foreach ($path in $logPaths) {
    try {
        Write-Output "Checking path: $path" | Tee-Object -FilePath $logFile -Append

        $files = Get-ChildItem -Path $path -File -ErrorAction Stop | Where-Object { $_.LastWriteTime -lt $cutoffDate }

        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                Write-Output "Deleted: $($file.FullName) [Last Modified: $($file.LastWriteTime)]" | Tee-Object -FilePath $logFile -Append
            } catch {
                Write-Output "❌ Failed to delete: $($file.FullName) - $_" | Tee-Object -FilePath $logFile -Append
            }
        }

        if ($files.Count -eq 0) {
            Write-Output "No files older than $daysOld days found in: $path" | Tee-Object -FilePath $logFile -Append
        }
    } catch {
        Write-Output "❌ Error accessing path: $path - $_" | Tee-Object -FilePath $logFile -Append
    }
}

Write-Output "✅ Log cleanup completed at $(Get-Date)" | Tee-Object -FilePath $logFile -Append
