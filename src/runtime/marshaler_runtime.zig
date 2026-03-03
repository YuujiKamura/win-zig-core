const std = @import("std");
const rt = @import("com_runtime.zig");

const log = std.log.scoped(.winui3);

const CoCreateFreeThreadedMarshalerFn = *const fn (?*anyopaque, *?*anyopaque) callconv(.winapi) rt.HRESULT;

const IMarshalVTable = extern struct {
    QueryInterface: *const fn (*anyopaque, *const rt.GUID, *?*anyopaque) callconv(.winapi) rt.HRESULT,
    AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
    Release: *const fn (*anyopaque) callconv(.winapi) u32,
    GetUnmarshalClass: *const fn (*anyopaque, *const rt.GUID, ?*anyopaque, u32, ?*anyopaque, u32, *rt.GUID) callconv(.winapi) rt.HRESULT,
    GetMarshalSizeMax: *const fn (*anyopaque, *const rt.GUID, ?*anyopaque, u32, ?*anyopaque, u32, *u32) callconv(.winapi) rt.HRESULT,
    MarshalInterface: *const fn (*anyopaque, ?*anyopaque, *const rt.GUID, ?*anyopaque, u32, ?*anyopaque, u32) callconv(.winapi) rt.HRESULT,
    UnmarshalInterface: *const fn (*anyopaque, ?*anyopaque, *const rt.GUID, *?*anyopaque) callconv(.winapi) rt.HRESULT,
    ReleaseMarshalData: *const fn (*anyopaque, ?*anyopaque) callconv(.winapi) rt.HRESULT,
    DisconnectObject: *const fn (*anyopaque, u32) callconv(.winapi) rt.HRESULT,
};

const MarshalerBox = struct {
    const ComHeader = extern struct {
        lpVtbl: *const IMarshalVTable,
    };

    com: ComHeader,
    allocator: std.mem.Allocator,
    ref_count: std.atomic.Value(u32),
    outer: *anyopaque,
    inner_imarshal: *anyopaque,

    const vtable_instance = IMarshalVTable{
        .QueryInterface = &queryInterfaceFn,
        .AddRef = &addRefFn,
        .Release = &releaseFn,
        .GetUnmarshalClass = &getUnmarshalClassFn,
        .GetMarshalSizeMax = &getMarshalSizeMaxFn,
        .MarshalInterface = &marshalInterfaceFn,
        .UnmarshalInterface = &unmarshalInterfaceFn,
        .ReleaseMarshalData = &releaseMarshalDataFn,
        .DisconnectObject = &disconnectObjectFn,
    };

    fn fromComPtr(ptr: *anyopaque) *MarshalerBox {
        const header: *ComHeader = @ptrCast(@alignCast(ptr));
        return @fieldParentPtr("com", header);
    }

    fn queryInterfaceFn(this: *anyopaque, riid: *const rt.GUID, ppv: *?*anyopaque) callconv(.winapi) rt.HRESULT {
        const self = fromComPtr(this);
        if (rt.guidEql(riid, &rt.IID_IUnknown) or rt.guidEql(riid, &rt.IID_IMarshal)) {
            ppv.* = this;
            _ = self.ref_count.fetchAdd(1, .monotonic);
            return rt.S_OK;
        }
        return rt.unknownQueryInterface(self.outer, riid, ppv);
    }

    fn addRefFn(this: *anyopaque) callconv(.winapi) u32 {
        const self = fromComPtr(this);
        return self.ref_count.fetchAdd(1, .monotonic) + 1;
    }

    fn releaseFn(this: *anyopaque) callconv(.winapi) u32 {
        const self = fromComPtr(this);
        const prev = self.ref_count.fetchSub(1, .monotonic);
        const next = prev - 1;
        if (next == 0) {
            _ = rt.unknownRelease(self.inner_imarshal);
            _ = rt.unknownRelease(self.outer);
            self.allocator.destroy(self);
        }
        return next;
    }

    fn getUnmarshalClassFn(this: *anyopaque, riid: *const rt.GUID, pv: ?*anyopaque, dwdestcontext: u32, pvdestcontext: ?*anyopaque, mshlflags: u32, pcid: *rt.GUID) callconv(.winapi) rt.HRESULT {
        const self = fromComPtr(this);
        const inner_vtbl: *const IMarshalVTable = @ptrCast(@alignCast((@as(*const *const IMarshalVTable, @ptrCast(@alignCast(self.inner_imarshal))).*)));
        return inner_vtbl.GetUnmarshalClass(self.inner_imarshal, riid, pv, dwdestcontext, pvdestcontext, mshlflags, pcid);
    }

    fn getMarshalSizeMaxFn(this: *anyopaque, riid: *const rt.GUID, pv: ?*anyopaque, dwdestcontext: u32, pvdestcontext: ?*anyopaque, mshlflags: u32, psize: *u32) callconv(.winapi) rt.HRESULT {
        const self = fromComPtr(this);
        const inner_vtbl: *const IMarshalVTable = @ptrCast(@alignCast((@as(*const *const IMarshalVTable, @ptrCast(@alignCast(self.inner_imarshal))).*)));
        return inner_vtbl.GetMarshalSizeMax(self.inner_imarshal, riid, pv, dwdestcontext, pvdestcontext, mshlflags, psize);
    }

    fn marshalInterfaceFn(this: *anyopaque, pstm: ?*anyopaque, riid: *const rt.GUID, pv: ?*anyopaque, dwdestcontext: u32, pvdestcontext: ?*anyopaque, mshlflags: u32) callconv(.winapi) rt.HRESULT {
        const self = fromComPtr(this);
        const inner_vtbl: *const IMarshalVTable = @ptrCast(@alignCast((@as(*const *const IMarshalVTable, @ptrCast(@alignCast(self.inner_imarshal))).*)));
        return inner_vtbl.MarshalInterface(self.inner_imarshal, pstm, riid, pv, dwdestcontext, pvdestcontext, mshlflags);
    }

    fn unmarshalInterfaceFn(this: *anyopaque, pstm: ?*anyopaque, riid: *const rt.GUID, ppv: *?*anyopaque) callconv(.winapi) rt.HRESULT {
        const self = fromComPtr(this);
        const inner_vtbl: *const IMarshalVTable = @ptrCast(@alignCast((@as(*const *const IMarshalVTable, @ptrCast(@alignCast(self.inner_imarshal))).*)));
        return inner_vtbl.UnmarshalInterface(self.inner_imarshal, pstm, riid, ppv);
    }

    fn releaseMarshalDataFn(this: *anyopaque, pstm: ?*anyopaque) callconv(.winapi) rt.HRESULT {
        const self = fromComPtr(this);
        const inner_vtbl: *const IMarshalVTable = @ptrCast(@alignCast((@as(*const *const IMarshalVTable, @ptrCast(@alignCast(self.inner_imarshal))).*)));
        return inner_vtbl.ReleaseMarshalData(self.inner_imarshal, pstm);
    }

    fn disconnectObjectFn(this: *anyopaque, dwreserved: u32) callconv(.winapi) rt.HRESULT {
        const self = fromComPtr(this);
        const inner_vtbl: *const IMarshalVTable = @ptrCast(@alignCast((@as(*const *const IMarshalVTable, @ptrCast(@alignCast(self.inner_imarshal))).*)));
        return inner_vtbl.DisconnectObject(self.inner_imarshal, dwreserved);
    }
};

fn getCoCreateFreeThreadedMarshaler() ?CoCreateFreeThreadedMarshalerFn {
    const dll_name = std.unicode.utf8ToUtf16LeStringLiteral("combase.dll");
    const module = std.os.windows.kernel32.LoadLibraryW(dll_name) orelse return null;
    const proc = std.os.windows.kernel32.GetProcAddress(module, "CoCreateFreeThreadedMarshaler") orelse return null;
    return @ptrCast(proc);
}

pub fn queryInterfaceAsMarshaler(
    allocator: std.mem.Allocator,
    outer: *anyopaque,
    ppv: *?*anyopaque,
) rt.HRESULT {
    const create_ftm = getCoCreateFreeThreadedMarshaler() orelse {
        log.err("CoCreateFreeThreadedMarshaler not found", .{});
        ppv.* = null;
        return rt.E_NOINTERFACE;
    };

    var unk: ?*anyopaque = null;
    const hr_create = create_ftm(null, &unk);
    if (hr_create < 0 or unk == null) {
        ppv.* = null;
        return hr_create;
    }
    const unk_ptr = unk.?;

    var inner_imarshal: ?*anyopaque = null;
    const hr_qi = rt.unknownQueryInterface(unk_ptr, &rt.IID_IMarshal, &inner_imarshal);
    _ = rt.unknownRelease(unk_ptr);
    if (hr_qi < 0 or inner_imarshal == null) {
        ppv.* = null;
        return hr_qi;
    }

    const box = allocator.create(MarshalerBox) catch {
        _ = rt.unknownRelease(inner_imarshal.?);
        ppv.* = null;
        return rt.E_NOINTERFACE;
    };
    _ = rt.unknownAddRef(outer);
    box.* = .{
        .com = .{ .lpVtbl = &MarshalerBox.vtable_instance },
        .allocator = allocator,
        .ref_count = std.atomic.Value(u32).init(1),
        .outer = outer,
        .inner_imarshal = inner_imarshal.?,
    };
    ppv.* = @ptrCast(&box.com);
    return rt.S_OK;
}

