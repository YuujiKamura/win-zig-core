param(
    [string]$RepoRoot = "C:\Users\yuuji\ghostty-win"
)

$ErrorActionPreference = "Stop"
$appPath = Join-Path $RepoRoot "src\apprt\winui3\App.zig"
if (-not (Test-Path -LiteralPath $appPath)) {
    throw "App.zig not found: $appPath"
}

$raw = Get-Content -Raw -Path $appPath

# 1) Ensure delegate IID-aware handler creation.
$raw = $raw.Replace(
    'self.tab_close_handler = try event.SimpleEventHandler(App).create(alloc, self, &onTabCloseRequested);',
    'self.tab_close_handler = try event.SimpleEventHandler(App).createWithIid(alloc, self, &onTabCloseRequested, &com.IID_TypedEventHandler_TabCloseRequested);'
)
$raw = $raw.Replace(
    'self.add_tab_handler = try event.SimpleEventHandler(App).create(alloc, self, &onAddTabButtonClick);',
    'self.add_tab_handler = try event.SimpleEventHandler(App).createWithIid(alloc, self, &onAddTabButtonClick, &com.IID_TypedEventHandler_AddTabButtonClick);'
)
$raw = $raw.Replace(
    'self.selection_changed_handler = try event.SimpleEventHandler(App).create(alloc, self, &onSelectionChanged);',
    'self.selection_changed_handler = try event.SimpleEventHandler(App).createWithIid(alloc, self, &onSelectionChanged, &com.IID_SelectionChangedEventHandler);'
)

# 2) Move TabView handler registration block after Step 8 (control tree creation).
$startMarker = "    // Register TabView event handlers (only if TabView was created)."
$step8Marker = "    // Step 8: Create the initial Surface (terminal) inside a TabViewItem."
$endStep8Marker = "    } // end TABVIEW_EMPTY else"

$start = $raw.IndexOf($startMarker)
$step8 = $raw.IndexOf($step8Marker)
$endStep8 = $raw.IndexOf($endStep8Marker)

if ($start -ge 0 -and $step8 -gt $start -and $endStep8 -gt $step8) {
    $block = $raw.Substring($start, $step8 - $start)
    $withoutBlock = $raw.Remove($start, $step8 - $start)

    # Recompute insertion point on updated content.
    $insertAt = $withoutBlock.IndexOf($endStep8Marker)
    if ($insertAt -ge 0) {
        $insertAt = $insertAt + $endStep8Marker.Length
        $insertion = "`r`n`r`n    // Step 8.5: Register TabView event handlers after control tree creation.`r`n" +
            ($block -replace [regex]::Escape($startMarker), "    // Register TabView event handlers (only if TabView was created).")
        $raw = $withoutBlock.Insert($insertAt, $insertion)
    } else {
        $raw = $withoutBlock
    }
}

Set-Content -Path $appPath -Value $raw -Encoding UTF8
Write-Host "Applied contract fixes to $appPath"
