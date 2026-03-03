param(
    [string]$GhosttyRoot = ""
)

$ErrorActionPreference = "Stop"

$scriptRepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $GhosttyRoot) {
    $siblingGhostty = Join-Path (Split-Path -Parent $scriptRepoRoot) "ghostty-win"
    if (Test-Path -LiteralPath (Join-Path $siblingGhostty "build.zig")) {
        $GhosttyRoot = $siblingGhostty
    } else {
        $GhosttyRoot = $scriptRepoRoot
    }
}
$repoRoot = $GhosttyRoot
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
