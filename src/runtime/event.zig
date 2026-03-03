//! Event adapter layer.
//!
//! Keep public API stable while delegating COM behavior to runtime modules.

const delegate = @import("delegate_runtime.zig");

pub fn TypedEventHandler(comptime Context: type, comptime CallbackFn: type) type {
    return delegate.TypedDelegate(Context, CallbackFn);
}

pub fn SimpleEventHandler(comptime Context: type) type {
    return delegate.TypedDelegate(Context, *const fn (*Context, *anyopaque, *anyopaque) void);
}

