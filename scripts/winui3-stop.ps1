$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $repoRoot "tmp\\ghostty-winui3.pid"

if (-not (Test-Path $pidFile)) {
    Write-Output "PID file not found. Nothing to stop."
    exit 0
}

$pidText = (Get-Content -Path $pidFile -Raw).Trim()
if (-not $pidText) {
    Write-Output "PID file is empty. Nothing to stop."
    Remove-Item -Path $pidFile -Force -ErrorAction SilentlyContinue
    exit 0
}

$targetPid = [int]$pidText
$proc = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
if ($null -eq $proc) {
    Write-Output ("Process {0} already exited." -f $targetPid)
    Remove-Item -Path $pidFile -Force -ErrorAction SilentlyContinue
    exit 0
}

Stop-Process -Id $targetPid -Force
Remove-Item -Path $pidFile -Force -ErrorAction SilentlyContinue
Write-Output ("Stopped ghostty (PID={0})" -f $targetPid)
