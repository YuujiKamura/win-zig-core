param(
    [string]$RepoRoot = "C:\Users\yuuji\ghostty-win",
    [string]$WinmdPath = ""
)

$ErrorActionPreference = "Stop"

$syncScript = Join-Path $RepoRoot "scripts\winui3-sync-delegate-iids.ps1"
if (-not (Test-Path -LiteralPath $syncScript)) {
    throw "Script not found: $syncScript"
}

$args = @("-RepoRoot", $RepoRoot, "-Check")
if ($WinmdPath) {
    $args += @("-WinmdPath", $WinmdPath)
}

pwsh -File $syncScript @args
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "winui3-delegate-iid-check: FAIL (com.zig delegate IID constants are out of sync)"
    exit $exitCode
}

Write-Host "winui3-delegate-iid-check: PASS"
exit 0

