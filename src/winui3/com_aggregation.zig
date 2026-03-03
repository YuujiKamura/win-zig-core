/// COM aggregation helpers for WinUI 3 Application runtime.
///
/// Contains InitCallback (Application.Start() delegate), AppOuter (COM aggregation
/// wrapper for IXamlMetadataProvider), and guidEql helper.
const std = @import("std");
const winrt = @import("winrt.zig");
const com = @import("com.zig");
const App = @import("App.zig");

const log = std.log.scoped(.winui3);

// ---------------------------------------------------------------
// ApplicationInitializationCallback — WinRT delegate for Application.Start()
// IID: {D8EEF1C9-1234-56F1-9963-45DD9C80A661}
// WinMD blob: 01 00 C9 F1 EE D8 34 12 F1 56 99 63 45 DD 9C 80 A6 61 00 00
// vtable: IUnknown(0-2) + Invoke(3)
// ---------------------------------------------------------------

pub const InitCallback = struct {
    /// COM-visible part — extern struct with lpVtbl at offset 0.
    com: Com,
    app: *App,

    const Com = extern struct {
        lpVtbl: *const VTable,

        const VTable = extern struct {
            QueryInterface: *const fn (*anyopaque, *const winrt.GUID, *?*anyopaque) callconv(.winapi) winrt.HRESULT,
            AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
            Release: *const fn (*anyopaque) callconv(.winapi) u32,
            Invoke: *const fn (*anyopaque, *anyopaque) callconv(.winapi) winrt.HRESULT,
        };
    };

    const vtable_inst = Com.VTable{
        .QueryInterface = &qiFn,
        .AddRef = &addRefFn,
        .Release = &releaseFn,
        .Invoke = &invokeFn,
    };

    pub fn create(app: *App) InitCallback {
        return .{
            .com = .{ .lpVtbl = &vtable_inst },
            .app = app,
        };
    }

    pub fn comPtr(self: *InitCallback) *anyopaque {
        return @ptrCast(&self.com);
    }

    fn fromComPtr(ptr: *anyopaque) *InitCallback {
        const com_ptr: *Com = @ptrCast(@alignCast(ptr));
        return @fieldParentPtr("com", com_ptr);
    }

    fn qiFn(this: *anyopaque, riid: *const winrt.GUID, ppv: *?*anyopaque) callconv(.winapi) winrt.HRESULT {
        const IID_IUnknown = winrt.GUID{ .Data1 = 0x00000000, .Data2 = 0x0000, .Data3 = 0x0000, .Data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 } };
        const IID_IAgileObject = winrt.GUID{ .Data1 = 0x94ea2b94, .Data2 = 0xe9cc, .Data3 = 0x49e0, .Data4 = .{ 0xc0, 0xff, 0xee, 0x64, 0xca, 0x8f, 0x5b, 0x90 } };
        const IID_Self = winrt.GUID{ .Data1 = 0xd8eef1c9, .Data2 = 0x1234, .Data3 = 0x56f1, .Data4 = .{ 0x99, 0x63, 0x45, 0xdd, 0x9c, 0x80, 0xa6, 0x61 } };

        if (guidEql(riid, &IID_IUnknown) or guidEql(riid, &IID_IAgileObject) or guidEql(riid, &IID_Self)) {
            ppv.* = this;
            _ = addRefFn(this);
            return 0; // S_OK
        }
        ppv.* = null;
        return @bitCast(@as(u32, 0x80004002)); // E_NOINTERFACE
    }

    fn addRefFn(_: *anyopaque) callconv(.winapi) u32 {
        return 1;
    }

    fn releaseFn(_: *anyopaque) callconv(.winapi) u32 {
        return 1;
    }

    fn invokeFn(this: *anyopaque, _: *anyopaque) callconv(.winapi) winrt.HRESULT {
        const self = fromComPtr(this);
        self.app.initXaml() catch |err| {
            log.err("initXaml failed in Application.Start callback: {}", .{err});
            return @bitCast(@as(u32, 0x80004005)); // E_FAIL
        };
        return 0; // S_OK
    }
};

pub fn guidEql(a: *const winrt.GUID, b: *const winrt.GUID) bool {
    return a.Data1 == b.Data1 and a.Data2 == b.Data2 and a.Data3 == b.Data3 and
        std.mem.eql(u8, &a.Data4, &b.Data4);
}

// ---------------------------------------------------------------
// AppOuter — COM aggregation wrapper for Application
//
// WinUI 3 custom controls (TabView, etc.) require their XAML templates to be
// loaded via XamlControlsResources. The XAML framework discovers these templates
// by calling IXamlMetadataProvider on the Application object. In normal C++/WinRT
// apps, the XAML compiler generates this. Without a XAML compiler, we must
// implement the COM aggregation pattern manually:
//
//   1. AppOuter acts as the "outer" (controlling) IUnknown
//   2. IApplicationFactory::CreateInstance receives AppOuter as outer
//   3. The WinRT Application becomes the "inner" (non-delegating) object
//   4. QI for IXamlMetadataProvider → AppOuter handles it, delegating to
//      an activated XamlControlsXamlMetaDataProvider instance
//   5. QI for anything else → delegates to inner
// ---------------------------------------------------------------

pub const AppOuter = struct {
    /// The COM-visible IUnknown vtable pointer — must be at offset 0.
    iunknown: IUnknownVtblPtr,
    /// The IXamlMetadataProvider vtable pointer — at offset 8.
    imetadata: IMetadataVtblPtr,
    /// Reference count. Must be atomic because we expose IXamlMetadataProvider
    /// to the XAML framework, which may call AddRef/Release from background
    /// threads during template resolution and layout.
    ref_count: std.atomic.Value(u32),
    /// The inner (non-delegating) IInspectable from Application.
    inner: ?*winrt.IInspectable,
    /// XamlControlsXamlMetaDataProvider instance for IXamlMetadataProvider delegation.
    provider: ?*com.IXamlMetadataProvider,

    const IUnknownVtblPtr = extern struct {
        lpVtbl: *const IUnknownVtbl,
    };
    const IUnknownVtbl = extern struct {
        QueryInterface: *const fn (*anyopaque, *const winrt.GUID, *?*anyopaque) callconv(.winapi) winrt.HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
    };

    const IMetadataVtblPtr = extern struct {
        lpVtbl: *const IMetadataVtbl,
    };
    const IMetadataVtbl = extern struct {
        // IUnknown (slots 0-2) — delegating to outer
        QueryInterface: *const fn (*anyopaque, *const winrt.GUID, *?*anyopaque) callconv(.winapi) winrt.HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: *const fn (*anyopaque, *u32, *?[*]winrt.GUID) callconv(.winapi) winrt.HRESULT,
        GetRuntimeClassName: *const fn (*anyopaque, *?winrt.HSTRING) callconv(.winapi) winrt.HRESULT,
        GetTrustLevel: *const fn (*anyopaque, *u32) callconv(.winapi) winrt.HRESULT,
        // IXamlMetadataProvider (slots 6-8)
        GetXamlType: *const fn (*anyopaque, [*]const u8, *?*anyopaque) callconv(.winapi) winrt.HRESULT,
        GetXamlType_2: *const fn (*anyopaque, ?winrt.HSTRING, *?*anyopaque) callconv(.winapi) winrt.HRESULT,
        GetXmlnsDefinitions: *const fn (*anyopaque, *u32, *?[*]*anyopaque) callconv(.winapi) winrt.HRESULT,
    };

    const iunknown_vtable = IUnknownVtbl{
        .QueryInterface = &outerQueryInterface,
        .AddRef = &outerAddRef,
        .Release = &outerRelease,
    };

    const imetadata_vtable = IMetadataVtbl{
        .QueryInterface = &metadataQueryInterface,
        .AddRef = &metadataAddRef,
        .Release = &metadataRelease,
        .GetIids = &metadataGetIids,
        .GetRuntimeClassName = &metadataGetRuntimeClassName,
        .GetTrustLevel = &metadataGetTrustLevel,
        .GetXamlType = &metadataGetXamlType,
        .GetXamlType_2 = &metadataGetXamlType2,
        .GetXmlnsDefinitions = &metadataGetXmlnsDefinitions,
    };

    pub fn init(self: *AppOuter) void {
        self.* = .{
            .iunknown = .{ .lpVtbl = &iunknown_vtable },
            .imetadata = .{ .lpVtbl = &imetadata_vtable },
            .ref_count = std.atomic.Value(u32).init(1),
            .inner = null,
            .provider = null,
        };
    }

    pub fn outerPtr(self: *AppOuter) *anyopaque {
        return @ptrCast(&self.iunknown);
    }

    fn fromIUnknownPtr(ptr: *anyopaque) *AppOuter {
        const p: *IUnknownVtblPtr = @ptrCast(@alignCast(ptr));
        return @fieldParentPtr("iunknown", p);
    }

    fn fromIMetadataPtr(ptr: *anyopaque) *AppOuter {
        const p: *IMetadataVtblPtr = @ptrCast(@alignCast(ptr));
        return @fieldParentPtr("imetadata", p);
    }

    // --- Outer IUnknown (controlling unknown) ---

    fn outerQueryInterface(this: *anyopaque, riid: *const winrt.GUID, ppv: *?*anyopaque) callconv(.winapi) winrt.HRESULT {
        const self = fromIUnknownPtr(this);
        const IID_IUnknown = winrt.GUID{ .Data1 = 0x00000000, .Data2 = 0x0000, .Data3 = 0x0000, .Data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 } };

        // Log EVERY QI request with IID and inner state for crash diagnosis.
        log.info("outerQI: iid={{{x:0>8}-{x:0>4}-{x:0>4}-{x:0>2}{x:0>2}-{x:0>2}{x:0>2}{x:0>2}{x:0>2}{x:0>2}{x:0>2}}} inner={}", .{
            riid.Data1,      riid.Data2,      riid.Data3,
            riid.Data4[0],   riid.Data4[1],   riid.Data4[2], riid.Data4[3],
            riid.Data4[4],   riid.Data4[5],   riid.Data4[6], riid.Data4[7],
            @intFromPtr(self.inner),
        });

        // IXamlMetadataProvider → return our metadata interface
        if (guidEql(riid, &com.IXamlMetadataProvider.IID)) {
            log.info("outerQI: -> IXamlMetadataProvider (handled by outer)", .{});
            ppv.* = @ptrCast(&self.imetadata);
            _ = outerAddRef(this);
            return 0; // S_OK
        }

        // IUnknown → return outer (the controlling unknown).
        // NOTE: IAgileObject is intentionally NOT handled here. We delegate it
        // to the inner Application object, which decides its own apartment model.
        // Previously we claimed agile, which told WinRT it could call us from any
        // thread — but our IXamlMetadataProvider callbacks delegate to the provider
        // which may not be thread-safe.
        if (guidEql(riid, &IID_IUnknown)) {
            log.info("outerQI: -> IUnknown (handled by outer)", .{});
            ppv.* = this;
            _ = outerAddRef(this);
            return 0; // S_OK
        }

        // Everything else → delegate to inner (non-delegating QI)
        if (self.inner) |inner| {
            const hr = inner.lpVtbl.QueryInterface(@ptrCast(inner), riid, ppv);
            log.info("outerQI: -> delegated to inner, hr=0x{x:0>8}", .{@as(u32, @bitCast(hr))});
            return hr;
        }

        ppv.* = null;
        log.info("outerQI: -> NO INNER, returning E_NOINTERFACE", .{});
        return @bitCast(@as(u32, 0x80004002)); // E_NOINTERFACE
    }

    fn outerAddRef(this: *anyopaque) callconv(.winapi) u32 {
        const self = fromIUnknownPtr(this);
        return self.ref_count.fetchAdd(1, .monotonic) + 1;
    }

    fn outerRelease(this: *anyopaque) callconv(.winapi) u32 {
        const self = fromIUnknownPtr(this);
        const prev = self.ref_count.fetchSub(1, .monotonic);
        return prev - 1;
    }

    // --- IXamlMetadataProvider interface (delegating IUnknown to outer) ---

    fn metadataQueryInterface(this: *anyopaque, riid: *const winrt.GUID, ppv: *?*anyopaque) callconv(.winapi) winrt.HRESULT {
        const self = fromIMetadataPtr(this);
        return outerQueryInterface(@ptrCast(&self.iunknown), riid, ppv);
    }

    fn metadataAddRef(this: *anyopaque) callconv(.winapi) u32 {
        const self = fromIMetadataPtr(this);
        return outerAddRef(@ptrCast(&self.iunknown));
    }

    fn metadataRelease(this: *anyopaque) callconv(.winapi) u32 {
        const self = fromIMetadataPtr(this);
        return outerRelease(@ptrCast(&self.iunknown));
    }

    fn metadataGetIids(_: *anyopaque, count: *u32, iids: *?[*]winrt.GUID) callconv(.winapi) winrt.HRESULT {
        count.* = 0;
        iids.* = null;
        return 0; // S_OK
    }

    fn metadataGetRuntimeClassName(_: *anyopaque, name: *?winrt.HSTRING) callconv(.winapi) winrt.HRESULT {
        name.* = null;
        return 0; // S_OK
    }

    fn metadataGetTrustLevel(_: *anyopaque, level: *u32) callconv(.winapi) winrt.HRESULT {
        level.* = 0; // BaseTrust
        return 0; // S_OK
    }

    fn metadataGetXamlType(this: *anyopaque, type_name: [*]const u8, result: *?*anyopaque) callconv(.winapi) winrt.HRESULT {
        log.info("metadataGetXamlType called (slot 6, TypeName overload)", .{});
        const self = fromIMetadataPtr(this);
        if (self.provider) |provider| {
            const hr = provider.lpVtbl.GetXamlType(@ptrCast(provider), type_name, result);
            log.info("metadataGetXamlType delegated, hr=0x{x}", .{@as(u32, @bitCast(hr))});
            return hr;
        }
        result.* = null;
        return 0; // S_OK — return null IXamlType (type not found)
    }

    fn metadataGetXamlType2(this: *anyopaque, full_name: ?winrt.HSTRING, result: *?*anyopaque) callconv(.winapi) winrt.HRESULT {
        log.info("metadataGetXamlType2 called (slot 7, HSTRING overload)", .{});
        const self = fromIMetadataPtr(this);
        if (self.provider) |provider| {
            const hr = provider.lpVtbl.GetXamlType_2(@ptrCast(provider), full_name, result);
            log.info("metadataGetXamlType2 delegated, hr=0x{x}", .{@as(u32, @bitCast(hr))});
            return hr;
        }
        result.* = null;
        return 0; // S_OK — return null IXamlType (type not found)
    }

    fn metadataGetXmlnsDefinitions(this: *anyopaque, count: *u32, definitions: *?[*]*anyopaque) callconv(.winapi) winrt.HRESULT {
        const self = fromIMetadataPtr(this);
        if (self.provider) |provider| {
            return provider.lpVtbl.GetXmlnsDefinitions(@ptrCast(provider), count, definitions);
        }
        count.* = 0;
        definitions.* = null;
        return 0; // S_OK
    }
};
