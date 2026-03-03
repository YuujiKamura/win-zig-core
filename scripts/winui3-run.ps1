$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $repoRoot "zig-out\\bin\\ghostty.exe"
$stateDir = Join-Path $repoRoot "tmp"
$pidFile = Join-Path $stateDir "ghostty-winui3.pid"

if (-not (Test-Path $exe)) {
    Write-Error "ghostty.exe not found: $exe"
}

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

$p = Start-Process -FilePath $exe -PassThru
$p.Id | Set-Content -Path $pidFile -Encoding ascii

Write-Output ("Started ghostty (PID={0})" -f $p.Id)
Write-Output ("PID file: {0}" -f $pidFile)
