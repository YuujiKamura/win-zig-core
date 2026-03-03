param(
    [Parameter(Mandatory = $true)]
    [string]$ReferenceJson,
    [Parameter(Mandatory = $true)]
    [string]$TargetJson,
    [string]$OutReport = "C:\Users\yuuji\ghostty-win\tmp\winui3-artifact-diff.md"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ReferenceJson)) { throw "Reference json not found: $ReferenceJson" }
if (-not (Test-Path -LiteralPath $TargetJson)) { throw "Target json not found: $TargetJson" }

$ref = Get-Content -Raw -Path $ReferenceJson | ConvertFrom-Json
$tgt = Get-Content -Raw -Path $TargetJson | ConvertFrom-Json

$refMap = @{}
foreach ($r in $ref) { $refMap[$r.RelativePath] = $r }

$tgtMap = @{}
foreach ($t in $tgt) { $tgtMap[$t.RelativePath] = $t }

$missing = @()
foreach ($k in $refMap.Keys) {
    if (-not $tgtMap.ContainsKey($k)) { $missing += $refMap[$k] }
}

$extra = @()
foreach ($k in $tgtMap.Keys) {
    if (-not $refMap.ContainsKey($k)) { $extra += $tgtMap[$k] }
}

$sizeDiff = @()
foreach ($k in $refMap.Keys) {
    if ($tgtMap.ContainsKey($k)) {
        $r = $refMap[$k]
        $t = $tgtMap[$k]
        if ([int64]$r.Size -ne [int64]$t.Size) {
            $sizeDiff += [pscustomobject]@{
                RelativePath = $k
                RefSize      = $r.Size
                TgtSize      = $t.Size
            }
        }
    }
}

$coreExt = @(".pri", ".xbf", ".winmd", ".manifest", ".dll")
$refCoreByName = @{}
foreach ($r in $ref) {
    if ($coreExt -contains $r.Extension) { $refCoreByName[$r.RelativePath.Split('\')[-1].ToLowerInvariant()] = $r }
}
$tgtCoreByName = @{}
foreach ($t in $tgt) {
    if ($coreExt -contains $t.Extension) { $tgtCoreByName[$t.RelativePath.Split('\')[-1].ToLowerInvariant()] = $t }
}

$missingCoreByName = @()
foreach ($k in $refCoreByName.Keys) {
    if (-not $tgtCoreByName.ContainsKey($k)) { $missingCoreByName += $refCoreByName[$k] }
}

$outDir = Split-Path -Parent $OutReport
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$lines = @()
$lines += "# WinUI3 Artifact Diff Report"
$lines += ""
$lines += "- Reference: ``$ReferenceJson``"
$lines += "- Target: ``$TargetJson``"
$lines += "- Missing in target: **$($missing.Count)**"
$lines += "- Extra in target: **$($extra.Count)**"
$lines += "- Size mismatch: **$($sizeDiff.Count)**"
$lines += "- Missing core artifacts by filename: **$($missingCoreByName.Count)**"
$lines += ""
$lines += "## Missing In Target"
if ($missing.Count -eq 0) {
    $lines += "- (none)"
} else {
    foreach ($m in ($missing | Sort-Object RelativePath)) {
        $lines += "- $($m.RelativePath) ($($m.Size) bytes)"
    }
}
$lines += ""
$lines += "## Missing Core Artifacts (Filename Match)"
if ($missingCoreByName.Count -eq 0) {
    $lines += "- (none)"
} else {
    foreach ($m in ($missingCoreByName | Sort-Object RelativePath)) {
        $name = $m.RelativePath.Split('\')[-1]
        $lines += "- $name (from $($m.RelativePath))"
    }
}
$lines += ""
$lines += "## Extra In Target"
if ($extra.Count -eq 0) {
    $lines += "- (none)"
} else {
    foreach ($e in ($extra | Sort-Object RelativePath)) {
        $lines += "- $($e.RelativePath) ($($e.Size) bytes)"
    }
}
$lines += ""
$lines += "## Size Mismatch"
if ($sizeDiff.Count -eq 0) {
    $lines += "- (none)"
} else {
    foreach ($s in ($sizeDiff | Sort-Object RelativePath)) {
        $lines += "- $($s.RelativePath): ref=$($s.RefSize), target=$($s.TgtSize)"
    }
}

$lines -join "`r`n" | Set-Content -Path $OutReport -Encoding UTF8
Write-Host "Report: $OutReport"
