# win-zig-core

`win-zig-core` is the WinRT/COM runtime wiring layer for Zig.

## Current Scope (split)

- Runtime layer (`src/runtime/`)
  - `delegate_runtime.zig`
  - `com_runtime.zig`
  - `marshaler_runtime.zig`
  - `event.zig`
- Sample host layer (`src/sample-host/winui3/`)
  - `App.zig`, `com.zig`, `com_aggregation.zig`, `os.zig`, `debug_harness.zig`
- Contract/smoke scripts (`scripts/winui3-*.ps1`)

## Validation

- `scripts/winui3-test.ps1`
- `scripts/winui3-contract-run.ps1`
- `zig build test` (runtime-only unit tests)

Notes:
- `scripts/winui3-test.ps1` / `scripts/winui3-run.ps1` accept `-GhosttyRoot` (defaults to sibling `../ghostty-win` if present).
- `scripts/winui3-contract-check.ps1` / `scripts/winui3-contract-run.ps1` accept `-BuildRoot` for WinUI3 app build location.
- `scripts/winui3-contract-run.ps1` also accepts:
  - `-SkipReference` to bypass reference-artifact comparison.
  - `-SkipExtractIids` to skip IID extraction from `debug.log`.

## Recommended Run Order

1. `win-zig-metadata`: `zig build test`
2. `win-zig-bindgen`: `zig build test`
3. `win-zig-bindgen`: `pwsh -File .\scripts\winui3-sync-delegate-iids.ps1 -Check`
4. `ghostty-win`: `pwsh -File .\scripts\winui3-delegate-iid-check.ps1`
5. `ghostty-win`: `pwsh -File .\scripts\winui3-inspect-event-params.ps1`
6. `win-zig-core`: `pwsh -File .\scripts\winui3-contract-run.ps1 -SkipReference -SkipExtractIids`

One-command orchestration from `win-zig-core`:

```powershell
pwsh -File .\scripts\winui3-verify-all.ps1
```

## Migration note

Source snapshot copied from `ghostty-win` commit `fe9218c`.
