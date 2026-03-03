const std = @import("std");
const winrt = @import("winrt.zig");

pub const HRESULT = winrt.HRESULT;
pub const GUID = winrt.GUID;

pub const S_OK: HRESULT = 0;
pub const E_NOINTERFACE: HRESULT = @bitCast(@as(u32, 0x80004002));

pub const IID_IUnknown = GUID{
    .Data1 = 0x00000000,
    .Data2 = 0x0000,
    .Data3 = 0x0000,
    .Data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 },
};

pub const IID_IAgileObject = GUID{
    .Data1 = 0x94ea2b94,
    .Data2 = 0xe9cc,
    .Data3 = 0x49e0,
    .Data4 = .{ 0xc0, 0xff, 0xee, 0x64, 0xca, 0x8f, 0x5b, 0x90 },
};

pub const IID_IMarshal = GUID{
    .Data1 = 0x00000003,
    .Data2 = 0x0000,
    .Data3 = 0x0000,
    .Data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 },
};

pub fn guidEql(a: *const GUID, b: *const GUID) bool {
    return a.Data1 == b.Data1 and
        a.Data2 == b.Data2 and
        a.Data3 == b.Data3 and
        std.mem.eql(u8, &a.Data4, &b.Data4);
}

pub const IUnknownVTable = extern struct {
    QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
    AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
    Release: *const fn (*anyopaque) callconv(.winapi) u32,
};

fn unknownVTable(this: *anyopaque) *const IUnknownVTable {
    const vtbl_ptr_ptr: *const *const IUnknownVTable = @ptrCast(@alignCast(this));
    return vtbl_ptr_ptr.*;
}

pub fn unknownQueryInterface(this: *anyopaque, riid: *const GUID, ppv: *?*anyopaque) HRESULT {
    return unknownVTable(this).QueryInterface(this, riid, ppv);
}

pub fn unknownAddRef(this: *anyopaque) u32 {
    return unknownVTable(this).AddRef(this);
}

pub fn unknownRelease(this: *anyopaque) u32 {
    return unknownVTable(this).Release(this);
}
