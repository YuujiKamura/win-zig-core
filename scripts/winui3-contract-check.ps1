param(
    [string]$RepoRoot = "C:\Users\yuuji\ghostty-win",
    [string]$RefRoot = "C:\Users\yuuji\winui3-reference",
    [string]$ContractPath = "C:\Users\yuuji\ghostty-win\contracts\winui-contract.json",
    [switch]$Build,
    [string]$OutReport = "C:\Users\yuuji\ghostty-win\tmp\winui3-contract-report.md"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ContractPath)) { throw "Contract not found: $ContractPath" }
if (-not (Test-Path -LiteralPath $RepoRoot)) { throw "RepoRoot not found: $RepoRoot" }
if (-not (Test-Path -LiteralPath $RefRoot)) { throw "RefRoot not found: $RefRoot" }

$contract = Get-Content -Raw -Path $ContractPath | ConvertFrom-Json

if ($Build) {
    Push-Location $RepoRoot
    try {
        zig build -Dapp-runtime=winui3 -Drenderer=d3d11 | Out-Null
    }
    finally {
        Pop-Location
    }
}

$tmpDir = Join-Path $RepoRoot "tmp"
if (-not (Test-Path -LiteralPath $tmpDir)) {
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
}
$refJson = Join-Path $tmpDir "ref-artifacts.json"
$tgtJson = Join-Path $tmpDir "ghostty-artifacts.json"
$diffMd = Join-Path $tmpDir "winui3-artifact-diff.md"

pwsh -File (Join-Path $RepoRoot "scripts\winui3-capture-artifacts.ps1") -Root $RefRoot -OutFile $refJson | Out-Null
pwsh -File (Join-Path $RepoRoot "scripts\winui3-capture-artifacts.ps1") -Root $RepoRoot -OutFile $tgtJson | Out-Null
pwsh -File (Join-Path $RepoRoot "scripts\winui3-diff-artifacts.ps1") -ReferenceJson $refJson -TargetJson $tgtJson -OutReport $diffMd | Out-Null

$ref = Get-Content -Raw -Path $refJson | ConvertFrom-Json
$tgt = Get-Content -Raw -Path $tgtJson | ConvertFrom-Json

$refNames = @{}
foreach ($r in $ref) { $refNames[$r.RelativePath.Split('\')[-1].ToLowerInvariant()] = $true }
$tgtNames = @{}
foreach ($t in $tgt) { $tgtNames[$t.RelativePath.Split('\')[-1].ToLowerInvariant()] = $true }

$results = @()

function Add-Result {
    param(
        [string]$Category,
        [string]$Item,
        [bool]$Pass,
        [string]$Detail
    )
    $script:results += [pscustomobject]@{
        Category = $Category
        Item = $Item
        Pass = $Pass
        Detail = $Detail
    }
}

foreach ($name in $contract.required_artifact_filenames) {
    $key = $name.ToLowerInvariant()
    $ok = $tgtNames.ContainsKey($key)
    $detail = if ($ok) { "found" } else { "missing in target artifacts" }
    Add-Result -Category "artifact-target" -Item $name -Pass $ok -Detail $detail
}

foreach ($name in $contract.required_reference_filenames) {
    $key = $name.ToLowerInvariant()
    $ok = $refNames.ContainsKey($key)
    $detail = if ($ok) { "found in reference" } else { "missing in reference build output" }
    Add-Result -Category "artifact-reference" -Item $name -Pass $ok -Detail $detail
}

foreach ($check in $contract.source_must_contain) {
    $filePath = Join-Path $RepoRoot $check.file
    if (-not (Test-Path -LiteralPath $filePath)) {
        Add-Result -Category "source" -Item "$($check.file)::$($check.pattern)" -Pass $false -Detail "file missing"
        continue
    }
    $content = Get-Content -Raw -Path $filePath
    $ok = $content -match [regex]::Escape($check.pattern)
    $detail = if ($ok) { "pattern exists" } else { "pattern missing" }
    Add-Result -Category "source" -Item "$($check.file)::$($check.pattern)" -Pass $ok -Detail $detail
}

foreach ($check in $contract.line_order_checks) {
    $filePath = Join-Path $RepoRoot $check.file
    if (-not (Test-Path -LiteralPath $filePath)) {
        Add-Result -Category "order" -Item "$($check.file)" -Pass $false -Detail "file missing"
        continue
    }
    $lines = Get-Content -Path $filePath
    $first = -1
    $second = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($first -lt 0 -and $lines[$i] -like "*$($check.first_pattern)*") { $first = $i }
        if ($second -lt 0 -and $lines[$i] -like "*$($check.second_pattern)*") { $second = $i }
    }
    if ($first -lt 0 -or $second -lt 0) {
        Add-Result -Category "order" -Item $check.description -Pass $false -Detail "pattern not found (first=$first second=$second)"
        continue
    }
    $ok = $first -lt $second
    Add-Result -Category "order" -Item $check.description -Pass $ok -Detail "line(first)=$($first+1), line(second)=$($second+1)"
}

$failCount = ($results | Where-Object { -not $_.Pass }).Count
$passCount = ($results | Where-Object { $_.Pass }).Count
$overall = if ($failCount -eq 0) { "PASS" } else { "FAIL" }

$outDir = Split-Path -Parent $OutReport
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$md = @()
$md += "# WinUI3 Contract Report"
$md += ""
$md += "- Contract: ``$ContractPath``"
$md += "- Repo: ``$RepoRoot``"
$md += "- Reference: ``$RefRoot``"
$md += "- Overall: **$overall**"
$md += "- Pass: **$passCount** / Fail: **$failCount**"
$md += "- Artifact diff: ``$diffMd``"
$md += ""
$md += "## Checks"
foreach ($r in $results) {
    $status = if ($r.Pass) { "PASS" } else { "FAIL" }
    $md += "- [$status] $($r.Category): $($r.Item) - $($r.Detail)"
}

$md -join "`r`n" | Set-Content -Path $OutReport -Encoding UTF8

Write-Host "OVERALL: $overall (pass=$passCount fail=$failCount)"
Write-Host "REPORT: $OutReport"
if ($failCount -gt 0) { exit 1 }
