const std = @import("std");
const rt = @import("com_runtime.zig");
const marshaler = @import("marshaler_runtime.zig");

const log = std.log.scoped(.winui3);

pub fn TypedDelegate(comptime Context: type, comptime CallbackFn: type) type {
    return struct {
        const Self = @This();

        pub const ComHeader = extern struct {
            lpVtbl: *const VTable,
        };

        pub const VTable = extern struct {
            QueryInterface: *const fn (*anyopaque, *const rt.GUID, *?*anyopaque) callconv(.winapi) rt.HRESULT,
            AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
            Release: *const fn (*anyopaque) callconv(.winapi) u32,
            Invoke: *const fn (*anyopaque, *anyopaque, *anyopaque) callconv(.winapi) rt.HRESULT,
        };

        com: ComHeader,
        allocator: std.mem.Allocator,
        ref_count: std.atomic.Value(u32),
        context: *Context,
        callback: CallbackFn,
        delegate_iid: ?*const rt.GUID = null,

        const vtable_instance = VTable{
            .QueryInterface = &queryInterfaceFn,
            .AddRef = &addRefFn,
            .Release = &releaseFn,
            .Invoke = &invokeFn,
        };

        pub fn create(
            allocator: std.mem.Allocator,
            context: *Context,
            callback: CallbackFn,
        ) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .com = .{ .lpVtbl = &vtable_instance },
                .allocator = allocator,
                .ref_count = std.atomic.Value(u32).init(1),
                .context = context,
                .callback = callback,
            };
            return self;
        }

        pub fn createWithIid(
            allocator: std.mem.Allocator,
            context: *Context,
            callback: CallbackFn,
            iid: *const rt.GUID,
        ) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .com = .{ .lpVtbl = &vtable_instance },
                .allocator = allocator,
                .ref_count = std.atomic.Value(u32).init(1),
                .context = context,
                .callback = callback,
                .delegate_iid = iid,
            };
            return self;
        }

        pub fn comPtr(self: *Self) *anyopaque {
            return @ptrCast(&self.com);
        }

        fn fromComPtr(ptr: *anyopaque) *Self {
            const header: *ComHeader = @ptrCast(@alignCast(ptr));
            return @fieldParentPtr("com", header);
        }

        fn queryInterfaceFn(
            this: *anyopaque,
            riid: *const rt.GUID,
            ppv: *?*anyopaque,
        ) callconv(.winapi) rt.HRESULT {
            const self = fromComPtr(this);
            if (rt.guidEql(riid, &rt.IID_IUnknown) or rt.guidEql(riid, &rt.IID_IAgileObject)) {
                ppv.* = this;
                _ = self.ref_count.fetchAdd(1, .monotonic);
                return rt.S_OK;
            }
            if (self.delegate_iid) |iid| {
                if (rt.guidEql(riid, iid)) {
                    ppv.* = this;
                    _ = self.ref_count.fetchAdd(1, .monotonic);
                    return rt.S_OK;
                }
            }
            if (rt.guidEql(riid, &rt.IID_IMarshal)) {
                return marshaler.queryInterfaceAsMarshaler(self.allocator, this, ppv);
            }

            log.warn("delegate QI unknown iid={{{x:0>8}-{x:0>4}-{x:0>4}-{x:0>2}{x:0>2}-{x:0>2}{x:0>2}{x:0>2}{x:0>2}{x:0>2}{x:0>2}}}", .{
                riid.Data1,
                riid.Data2,
                riid.Data3,
                riid.Data4[0],
                riid.Data4[1],
                riid.Data4[2],
                riid.Data4[3],
                riid.Data4[4],
                riid.Data4[5],
                riid.Data4[6],
                riid.Data4[7],
            });
            ppv.* = null;
            return rt.E_NOINTERFACE;
        }

        fn addRefFn(this: *anyopaque) callconv(.winapi) u32 {
            const self = fromComPtr(this);
            return self.ref_count.fetchAdd(1, .monotonic) + 1;
        }

        fn releaseFn(this: *anyopaque) callconv(.winapi) u32 {
            const self = fromComPtr(this);
            const prev = self.ref_count.fetchSub(1, .monotonic);
            const next = prev - 1;
            if (next == 0) self.allocator.destroy(self);
            return next;
        }

        fn invokeFn(this: *anyopaque, sender: *anyopaque, args: *anyopaque) callconv(.winapi) rt.HRESULT {
            const self = fromComPtr(this);
            self.callback(self.context, sender, args);
            return rt.S_OK;
        }
    };
}
