# Migration Order

1. Stabilize `win-zig-bindgen`
- Ensure `zig build` works standalone
- Keep delegate IID generation/check scripts green

2. Extract metadata layer into `win-zig-metadata`
- Move parser files from bindgen
- Replace bindgen internal imports with metadata package imports

3. Trim `win-zig-core` to runtime-only
- Keep `com_runtime/delegate_runtime/marshaler_runtime`
- Split host sample from reusable runtime

4. Reconnect consumer projects
- `ghostty-win` depends on `win-zig-core` + generated bindings from `win-zig-bindgen`
- Remove duplicated local runtime code after integration
