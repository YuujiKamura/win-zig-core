pub const com_runtime = @import("com_runtime.zig");
pub const delegate_runtime = @import("delegate_runtime.zig");
pub const marshaler_runtime = @import("marshaler_runtime.zig");
pub const event = @import("event.zig");

const std = @import("std");

test "runtime imports compile" {
    _ = com_runtime;
    _ = delegate_runtime;
    _ = marshaler_runtime;
    _ = event;
}

test "guidEql distinguishes equal and different GUIDs" {
    const rt = com_runtime;
    const a = rt.GUID{
        .Data1 = 1,
        .Data2 = 2,
        .Data3 = 3,
        .Data4 = .{ 4, 5, 6, 7, 8, 9, 10, 11 },
    };
    const b = a;
    const c = rt.GUID{
        .Data1 = 1,
        .Data2 = 2,
        .Data3 = 3,
        .Data4 = .{ 4, 5, 6, 7, 8, 9, 10, 12 },
    };
    try std.testing.expect(rt.guidEql(&a, &b));
    try std.testing.expect(!rt.guidEql(&a, &c));
}

test "TypedDelegate COM QI handles IUnknown and delegate IID" {
    const rt = com_runtime;
    const Typed = delegate_runtime.TypedDelegate(u8, *const fn (*u8, *anyopaque, *anyopaque) void);

    const Ctx = struct {
        fn cb(_: *u8, _: *anyopaque, _: *anyopaque) void {}
    };

    var ctx: u8 = 0;
    var delegate_iid = rt.GUID{
        .Data1 = 0x11111111,
        .Data2 = 0x2222,
        .Data3 = 0x3333,
        .Data4 = .{ 1, 2, 3, 4, 5, 6, 7, 8 },
    };

    const h = try Typed.createWithIid(std.testing.allocator, &ctx, &Ctx.cb, &delegate_iid);
    defer _ = h.com.lpVtbl.Release(@ptrCast(&h.com));

    var out: ?*anyopaque = null;
    const hr_unk = h.com.lpVtbl.QueryInterface(@ptrCast(&h.com), &rt.IID_IUnknown, &out);
    try std.testing.expectEqual(@as(rt.HRESULT, rt.S_OK), hr_unk);
    try std.testing.expect(out != null);
    _ = h.com.lpVtbl.Release(@ptrCast(&h.com));

    out = null;
    const hr_delegate = h.com.lpVtbl.QueryInterface(@ptrCast(&h.com), &delegate_iid, &out);
    try std.testing.expectEqual(@as(rt.HRESULT, rt.S_OK), hr_delegate);
    try std.testing.expect(out != null);
    _ = h.com.lpVtbl.Release(@ptrCast(&h.com));

    var unknown_iid = rt.GUID{
        // IGlobalInterfaceTable (known probe, still E_NOINTERFACE for delegates)
        .Data1 = 0x00000146,
        .Data2 = 0x0000,
        .Data3 = 0x0000,
        .Data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 },
    };
    out = null;
    const hr_unknown = h.com.lpVtbl.QueryInterface(@ptrCast(&h.com), &unknown_iid, &out);
    try std.testing.expectEqual(@as(rt.HRESULT, rt.E_NOINTERFACE), hr_unknown);
    try std.testing.expect(out == null);
}

test "marshaler resolver caches proc on first resolve" {
    const mr = marshaler_runtime;
    const rt = com_runtime;

    const fake = struct {
        fn resolver() ?*const fn (?*anyopaque, *?*anyopaque) callconv(.winapi) rt.HRESULT {
            return &ftm;
        }

        fn ftm(_: ?*anyopaque, out: *?*anyopaque) callconv(.winapi) rt.HRESULT {
            out.* = null;
            return rt.E_NOINTERFACE;
        }
    };

    mr.testSetResolver(&fake.resolver);
    defer mr.testResetResolver();

    const p1 = mr.testResolveForUnit();
    const p2 = mr.testResolveForUnit();
    try std.testing.expect(p1 != null);
    try std.testing.expect(p2 != null);
    try std.testing.expectEqual(@as(u32, 1), mr.testGetResolveCallCount());
}

test "marshaler resolver caches null failures" {
    const mr = marshaler_runtime;

    const fake = struct {
        fn resolver() ?*const fn (?*anyopaque, *?*anyopaque) callconv(.winapi) com_runtime.HRESULT {
            return null;
        }
    };

    mr.testSetResolver(&fake.resolver);
    defer mr.testResetResolver();

    try std.testing.expect(mr.testResolveForUnit() == null);
    try std.testing.expect(mr.testResolveForUnit() == null);
    try std.testing.expectEqual(@as(u32, 1), mr.testGetResolveCallCount());
}

test "known probe IIDs are classified correctly" {
    const known = com_runtime.GUID{
        .Data1 = 0x00000146,
        .Data2 = 0x0000,
        .Data3 = 0x0000,
        .Data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 },
    };
    const unknown = com_runtime.GUID{
        .Data1 = 0xaaaaaaaa,
        .Data2 = 0xbbbb,
        .Data3 = 0xcccc,
        .Data4 = .{ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 },
    };
    try std.testing.expect(delegate_runtime.isKnownProbeIid(&known));
    try std.testing.expect(!delegate_runtime.isKnownProbeIid(&unknown));
}
