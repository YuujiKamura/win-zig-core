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
        .Data1 = 0xaaaaaaaa,
        .Data2 = 0xbbbb,
        .Data3 = 0xcccc,
        .Data4 = .{ 0, 1, 2, 3, 4, 5, 6, 7 },
    };
    out = null;
    const hr_unknown = h.com.lpVtbl.QueryInterface(@ptrCast(&h.com), &unknown_iid, &out);
    try std.testing.expectEqual(@as(rt.HRESULT, rt.E_NOINTERFACE), hr_unknown);
    try std.testing.expect(out == null);
}

