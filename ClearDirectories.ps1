$Srvn = hostname
$Date = Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff"
$DaysOld = 7
$CutoffDate = (Get-Date).AddDays(-$DaysOld)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $scriptDir "log"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$log = Join-Path $logDir "folder_cleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$FolderList = Join-Path $scriptDir "folder_path.txt"
if (!(Test-Path $FolderList)) {
    Write-Output "$Date ❌ Folder list file not found: $FolderList" | Out-File $log -Append
    exit
}
$Paths = Get-Content $FolderList | Where-Object { $_.Trim() -ne "" }

foreach ($path in $Paths) {
    Write-Output "$Date 🔍 Checking: $path" | Out-File $log -Append

    if (Test-Path $path) {
        Get-ChildItem -Path $path -Directory -Force | Where-Object {
            $_.LastWriteTime -lt $CutoffDate
        } | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
                Write-Output "$Date ✅ Deleted: $($_.FullName)" | Out-File $log -Append
            } catch {
                Write-Output "$Date ❌ Failed to delete: $($_.FullName) - $_" | Out-File $log -Append
            }
        }
    } else {
        Write-Output "$Date ⚠️ Path not found: $path" | Out-File $log -Append
    }
}

Write-Output "$Date ✅ Folder cleanup completed on $Srvn" | Out-File $log -Append
