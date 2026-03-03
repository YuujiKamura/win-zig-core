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

## Migration note

Source snapshot copied from `ghostty-win` commit `fe9218c`.
