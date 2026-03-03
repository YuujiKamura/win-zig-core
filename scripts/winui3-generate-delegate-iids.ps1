param(
    [string]$RepoRoot = "C:\Users\yuuji\ghostty-win",
    [string]$ExePath = "C:\Users\yuuji\ghostty-win\zig-out\bin\ghostty.exe",
    [int]$WaitSeconds = 6,
    [switch]$BuildFirst
)

$ErrorActionPreference = "Stop"

if ($BuildFirst) {
    Push-Location $RepoRoot
    try {
        zig build -Dapp-runtime=winui3 -Drenderer=d3d11 | Out-Null
    }
    finally {
        Pop-Location
    }
}

$debugLog = Join-Path $RepoRoot "debug.log"
$mapOut = Join-Path $RepoRoot "tmp\winui3-delegate-iids.json"
$comPath = Join-Path $RepoRoot "src\apprt\winui3\com.zig"

$ignored = @(
    "ecc8691b-c1db-4dc0-855e-65f6c551af49", # INoMarshal
    "00000039-0000-0000-c000-000000000046", # IGlobalInterfaceTable
    "0000001b-0000-0000-c000-000000000046"  # IStdMarshalInfo
)

function Parse-UnknownIids([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $lines = Get-Content -Path $Path
    $capture = $false
    $hits = @()
    foreach ($line in $lines) {
        if ($line -like "*initXaml step 8 OK:*" -or $line -like "*initXaml step 8: append done*") {
            $capture = $true
            continue
        }
        if (-not $capture) { continue }
        if ($line -match "eventHandler QI: unknown iid=\{([0-9a-fA-F\-]+)\}") {
            $id = $matches[1].ToLowerInvariant()
            if ($ignored -notcontains $id) {
                $hits += $id
            }
        }
    }
    return @($hits | Sort-Object -Unique)
}

function Run-Probe([string]$Name, [string]$Close, [string]$AddTab, [string]$Selection) {
    Write-Host "=== Probe: $Name (close=$Close addtab=$AddTab selection=$Selection) ==="
    $env:GHOSTTY_WINUI3_ENABLE_TABVIEW = "1"
    $env:GHOSTTY_WINUI3_ENABLE_XAML_RESOURCES = "1"
    $env:GHOSTTY_WINUI3_ENABLE_TABVIEW_HANDLERS = "1"
    $env:GHOSTTY_WINUI3_HANDLER_CLOSE = $Close
    $env:GHOSTTY_WINUI3_HANDLER_ADDTAB = $AddTab
    $env:GHOSTTY_WINUI3_HANDLER_SELECTION = $Selection
    $env:GHOSTTY_WINUI3_TABVIEW_EMPTY = "0"
    $env:GHOSTTY_WINUI3_TABVIEW_ITEM_NO_CONTENT = "0"
    $env:GHOSTTY_WINUI3_TABVIEW_APPEND_ITEM = "1"
    $env:GHOSTTY_WINUI3_TABVIEW_SELECT_FIRST = "1"

    $p = Start-Process -FilePath $ExePath -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds $WaitSeconds
    if (-not $p.HasExited) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
    $iids = Parse-UnknownIids $debugLog
    Write-Host ("  Unknown IIDs: " + (($iids -join ", ")))
    return $iids
}

function Pick-Single([string[]]$arr, [string]$label) {
    if ($arr.Count -ne 1) {
        throw "Expected exactly one IID for $label, got $($arr.Count): $($arr -join ', ')"
    }
    return $arr[0]
}

function Guid-To-ZigLiteral([string]$guidText) {
    $parts = $guidText.ToLowerInvariant().Split("-")
    if ($parts.Count -ne 5) { throw "Invalid GUID: $guidText" }
    $d1 = "0x$($parts[0])"
    $d2 = "0x$($parts[1])"
    $d3 = "0x$($parts[2])"
    $tail = ($parts[3] + $parts[4])
    $bytes = @()
    for ($i = 0; $i -lt 16; $i += 2) {
        $bytes += "0x$($tail.Substring($i,2))"
    }
    return ".Data1 = $d1, .Data2 = $d2, .Data3 = $d3, .Data4 = .{ " + ($bytes -join ", ") + " }"
}

function Replace-ConstGuid([string]$text, [string]$constName, [string]$guidText) {
    $body = Guid-To-ZigLiteral $guidText
    $replacement = "pub const $constName = GUID{ $body };"
    $pattern = "pub const $constName = GUID\{[^;]*\};"
    return [regex]::Replace($text, $pattern, $replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
}

$closeOnly = Run-Probe -Name "close_only" -Close "true" -AddTab "false" -Selection "false"
$addtabOnly = Run-Probe -Name "addtab_only" -Close "false" -AddTab "true" -Selection "false"
$selectionOnly = Run-Probe -Name "selection_only" -Close "false" -AddTab "false" -Selection "true"

# Remove overlaps conservatively so each event maps to one IID.
$closeUnique = @($closeOnly | Where-Object { ($addtabOnly -notcontains $_) -and ($selectionOnly -notcontains $_) })
$addtabUnique = @($addtabOnly | Where-Object { ($closeOnly -notcontains $_) -and ($selectionOnly -notcontains $_) })
$selectionUnique = @($selectionOnly | Where-Object { ($closeOnly -notcontains $_) -and ($addtabOnly -notcontains $_) })

if ($closeUnique.Count -eq 0) { $closeUnique = $closeOnly }
if ($addtabUnique.Count -eq 0) { $addtabUnique = $addtabOnly }
if ($selectionUnique.Count -eq 0) { $selectionUnique = $selectionOnly }

$closeIid = Pick-Single $closeUnique "TabCloseRequested"
$addtabIid = Pick-Single $addtabUnique "AddTabButtonClick"
$selectionIid = Pick-Single $selectionUnique "SelectionChanged"

$map = [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    tab_close_requested = $closeIid
    add_tab_button_click = $addtabIid
    selection_changed = $selectionIid
}

$outDir = Split-Path -Parent $mapOut
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
$map | ConvertTo-Json -Depth 4 | Set-Content -Path $mapOut -Encoding UTF8
Write-Host "Wrote map: $mapOut"

if (-not (Test-Path -LiteralPath $comPath)) { throw "com.zig not found: $comPath" }
$comRaw = Get-Content -Raw -Path $comPath
$comRaw = Replace-ConstGuid -text $comRaw -constName "IID_TypedEventHandler_TabCloseRequested" -guidText $closeIid
$comRaw = Replace-ConstGuid -text $comRaw -constName "IID_TypedEventHandler_AddTabButtonClick" -guidText $addtabIid
$comRaw = Replace-ConstGuid -text $comRaw -constName "IID_SelectionChangedEventHandler" -guidText $selectionIid
Set-Content -Path $comPath -Value $comRaw -Encoding UTF8
Write-Host "Patched: $comPath"
