param(
    [switch]$Build,
    [switch]$Fix
)

$ErrorActionPreference = "Stop"
$repo = "C:\Users\yuuji\ghostty-win"

if ($Build) {
    Push-Location $repo
    try {
        zig build -Dapp-runtime=winui3 -Drenderer=d3d11 | Out-Null
    }
    finally {
        Pop-Location
    }
}

$fixExit = 0
if ($Fix) {
    pwsh -File "$repo\scripts\winui3-contract-fix.ps1"
    $fixExit = $LASTEXITCODE
    if ($fixExit -ne 0) { exit $fixExit }
}

$checkArgs = @()
if ($Build) { $checkArgs += "-Build" }
pwsh -File "$repo\scripts\winui3-contract-check.ps1" @checkArgs
$checkExit = $LASTEXITCODE
pwsh -File "$repo\scripts\winui3-delegate-iid-check.ps1" -RepoRoot $repo
$iidExit = $LASTEXITCODE
pwsh -File "$repo\scripts\winui3-extract-iids.ps1"
if ($checkExit -ne 0) { exit $checkExit }
if ($iidExit -ne 0) { exit $iidExit }
