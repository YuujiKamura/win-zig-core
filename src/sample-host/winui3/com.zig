//! WinUI 3 COM interface definitions for Zig.
//!
//! VTable definitions are auto-generated from Microsoft.UI.Xaml.winmd by winmd2zig.
//! Slot ordering matches ECMA-335 metadata exactly.
//!
//! To regenerate vtables:
//!   cd tools/winmd2zig && zig build run -- <path>/Microsoft.UI.Xaml.winmd \
//!     IApplicationStatics IApplicationFactory IApplication IWindow \
//!     ITabView ITabViewItem IContentControl
//!
//! Non-WinMD interfaces (IWindowNative, ISwapChainPanelNative, IVector) are
//! maintained manually 窶・they come from Windows SDK headers, not .winmd files.

const std = @import("std");
const winrt = @import("winrt.zig");

const HRESULT = winrt.HRESULT;
const GUID = winrt.GUID;
const HSTRING = winrt.HSTRING;
const HWND = winrt.HWND;
const VtblPlaceholder = winrt.VtblPlaceholder;
const IInspectable = winrt.IInspectable;
const hrCheck = winrt.hrCheck;
const WinRTError = winrt.WinRTError;

// ============================================================================
// IApplicationStatics 窶・Microsoft.UI.Xaml.IApplicationStatics
// Generated from WinMD
// ============================================================================

pub const IApplicationStatics = extern struct {
    // WinMD: Microsoft.UI.Xaml.IApplicationStatics
    // Blob: 01 00 f5 09 0d 4e 58 43 2c 51 a9 87 50 3b 52 84 8e 95 00 00
    pub const IID = GUID{ .Data1 = 0x4e0d09f5, .Data2 = 0x4358, .Data3 = 0x512c, .Data4 = .{ 0xa9, 0x87, 0x50, 0x3b, 0x52, 0x84, 0x8e, 0x95 } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IApplicationStatics (slots 6-9)
        get_Current: VtblPlaceholder, // 6
        Start: *const fn (*anyopaque, *anyopaque) callconv(.winapi) HRESULT, // 7
        LoadComponent: VtblPlaceholder, // 8
        LoadComponent_2: VtblPlaceholder, // 9
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn start(self: *IApplicationStatics, callback: *anyopaque) WinRTError!void {
        try hrCheck(self.lpVtbl.Start(@ptrCast(self), callback));
    }
};

// ============================================================================
// IApplicationFactory 窶・Microsoft.UI.Xaml.IApplicationFactory
// Generated from WinMD
// ============================================================================

pub const IApplicationFactory = extern struct {
    // WinMD: Microsoft.UI.Xaml.IApplicationFactory
    // Blob: 01 00 57 66 d9 9f 94 52 65 5a a1 db 4f ea 14 35 97 da 00 00
    pub const IID = GUID{ .Data1 = 0x9fd96657, .Data2 = 0x5294, .Data3 = 0x5a65, .Data4 = .{ 0xa1, 0xdb, 0x4f, 0xea, 0x14, 0x35, 0x97, 0xda } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IApplicationFactory (slot 6)
        CreateInstance: *const fn (*anyopaque, ?*anyopaque, *?*anyopaque, *?*anyopaque) callconv(.winapi) HRESULT, // 6
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    /// Create an Application instance with COM aggregation.
    /// `outer` is the controlling IUnknown (or null for non-aggregated creation).
    /// Returns the inner IInspectable (non-delegating) and the wrapper instance.
    pub fn createInstance(self: *IApplicationFactory, outer: ?*anyopaque) WinRTError!struct { inner: *IInspectable, instance: *IInspectable } {
        var inner: ?*anyopaque = null;
        var instance: ?*anyopaque = null;
        try hrCheck(self.lpVtbl.CreateInstance(@ptrCast(self), outer, &inner, &instance));
        return .{
            .inner = @ptrCast(@alignCast(inner orelse return error.WinRTFailed)),
            .instance = @ptrCast(@alignCast(instance orelse return error.WinRTFailed)),
        };
    }
};

// ============================================================================
// IApplication 窶・Microsoft.UI.Xaml.IApplication
// Generated from WinMD
// ============================================================================

pub const IApplication = extern struct {
    // WinMD: Microsoft.UI.Xaml.IApplication
    // Blob: 01 00 e7 f4 a8 06 46 11 af 55 82 0d eb d5 56 43 b0 21 00 00
    pub const IID = GUID{ .Data1 = 0x06a8f4e7, .Data2 = 0x1146, .Data3 = 0x55af, .Data4 = .{ 0x82, 0x0d, 0xeb, 0xd5, 0x56, 0x43, 0xb0, 0x21 } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IApplication (slots 6-17)
        get_Resources: *const fn (*anyopaque, *?*anyopaque) callconv(.winapi) HRESULT, // 6
        put_Resources: *const fn (*anyopaque, ?*anyopaque) callconv(.winapi) HRESULT, // 7
        get_DebugSettings: VtblPlaceholder, // 8
        get_RequestedTheme: VtblPlaceholder, // 9
        put_RequestedTheme: VtblPlaceholder, // 10
        get_FocusVisualKind: VtblPlaceholder, // 11
        put_FocusVisualKind: VtblPlaceholder, // 12
        get_HighContrastAdjustment: VtblPlaceholder, // 13
        put_HighContrastAdjustment: VtblPlaceholder, // 14
        add_UnhandledException: VtblPlaceholder, // 15
        remove_UnhandledException: VtblPlaceholder, // 16
        Exit: *const fn (*anyopaque) callconv(.winapi) HRESULT, // 17
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn getResources(self: *IApplication) WinRTError!*IInspectable {
        var result: ?*anyopaque = null;
        try hrCheck(self.lpVtbl.get_Resources(@ptrCast(self), &result));
        return @ptrCast(@alignCast(result orelse return error.WinRTFailed));
    }

    pub fn putResources(self: *IApplication, resources: ?*anyopaque) WinRTError!void {
        try hrCheck(self.lpVtbl.put_Resources(@ptrCast(self), resources));
    }

    pub fn exit(self: *IApplication) WinRTError!void {
        try hrCheck(self.lpVtbl.Exit(@ptrCast(self)));
    }
};

// ============================================================================
// IWindow 窶・Microsoft.UI.Xaml.IWindow
// Generated from WinMD
// ============================================================================

pub const IWindow = extern struct {
    // WinMD: Microsoft.UI.Xaml.IWindow
    // Blob: 01 00 79 ec f0 61 52 5d b5 56 86 fb 40 fa 4a f2 88 b0 00 00
    pub const IID = GUID{ .Data1 = 0x61f0ec79, .Data2 = 0x5d52, .Data3 = 0x56b5, .Data4 = .{ 0x86, 0xfb, 0x40, 0xfa, 0x4a, 0xf2, 0x88, 0xb0 } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IWindow (slots 6-28)
        get_Bounds: VtblPlaceholder, // 6
        get_Visible: VtblPlaceholder, // 7
        get_Content: VtblPlaceholder, // 8
        put_Content: *const fn (*anyopaque, ?*anyopaque) callconv(.winapi) HRESULT, // 9
        get_CoreWindow: VtblPlaceholder, // 10
        get_Compositor: VtblPlaceholder, // 11
        get_Dispatcher: VtblPlaceholder, // 12
        get_DispatcherQueue: VtblPlaceholder, // 13
        get_Title: VtblPlaceholder, // 14
        put_Title: *const fn (*anyopaque, ?HSTRING) callconv(.winapi) HRESULT, // 15
        get_ExtendsContentIntoTitleBar: VtblPlaceholder, // 16
        put_ExtendsContentIntoTitleBar: VtblPlaceholder, // 17
        add_Activated: VtblPlaceholder, // 18
        remove_Activated: VtblPlaceholder, // 19
        add_Closed: *const fn (*anyopaque, *anyopaque, *i64) callconv(.winapi) HRESULT, // 20
        remove_Closed: *const fn (*anyopaque, i64) callconv(.winapi) HRESULT, // 21
        add_SizeChanged: *const fn (*anyopaque, *anyopaque, *i64) callconv(.winapi) HRESULT, // 22
        remove_SizeChanged: VtblPlaceholder, // 23
        add_VisibilityChanged: VtblPlaceholder, // 24
        remove_VisibilityChanged: VtblPlaceholder, // 25
        Activate: *const fn (*anyopaque) callconv(.winapi) HRESULT, // 26
        Close: *const fn (*anyopaque) callconv(.winapi) HRESULT, // 27
        SetTitleBar: VtblPlaceholder, // 28
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn activate(self: *IWindow) WinRTError!void {
        try hrCheck(self.lpVtbl.Activate(@ptrCast(self)));
    }

    pub fn close(self: *IWindow) WinRTError!void {
        try hrCheck(self.lpVtbl.Close(@ptrCast(self)));
    }

    pub fn putContent(self: *IWindow, content: ?*anyopaque) WinRTError!void {
        try hrCheck(self.lpVtbl.put_Content(@ptrCast(self), content));
    }

    pub fn putTitle(self: *IWindow, title: ?HSTRING) WinRTError!void {
        try hrCheck(self.lpVtbl.put_Title(@ptrCast(self), title));
    }

    pub fn addClosed(self: *IWindow, handler: *anyopaque) WinRTError!i64 {
        var token: i64 = 0;
        try hrCheck(self.lpVtbl.add_Closed(@ptrCast(self), handler, &token));
        return token;
    }

    pub fn removeClosed(self: *IWindow, token: i64) WinRTError!void {
        try hrCheck(self.lpVtbl.remove_Closed(@ptrCast(self), token));
    }

    pub fn addSizeChanged(self: *IWindow, handler: *anyopaque) WinRTError!i64 {
        var token: i64 = 0;
        try hrCheck(self.lpVtbl.add_SizeChanged(@ptrCast(self), handler, &token));
        return token;
    }
};

// ============================================================================
// IWindowNative 窶・classic COM interface (not WinRT) for getting HWND
// IID: {EECDBF0E-BAE9-4CB6-A68E-9598E1CB57BB}
// NOT from WinMD 窶・from Windows SDK headers
// ============================================================================

pub const IWindowNative = extern struct {
    pub const IID = GUID{
        .Data1 = 0xeecdbf0e,
        .Data2 = 0xbae9,
        .Data3 = 0x4cb6,
        .Data4 = .{ 0xa6, 0x8e, 0x95, 0x98, 0xe1, 0xcb, 0x57, 0xbb },
    };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IWindowNative (slot 3)
        get_WindowHandle: *const fn (*anyopaque, *?HWND) callconv(.winapi) HRESULT,
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn getWindowHandle(self: *IWindowNative) WinRTError!HWND {
        var hwnd: ?HWND = null;
        try hrCheck(self.lpVtbl.get_WindowHandle(@ptrCast(self), &hwnd));
        return hwnd orelse error.WinRTFailed;
    }
};

// ============================================================================
// ISwapChainPanelNative 窶・classic COM interface for binding DXGI swap chain
// IID: {63AAD0B8-7C24-40FF-85A8-640D944CC325}
// NOT from WinMD 窶・from microsoft.ui.xaml.media.dxinterop.h
// ============================================================================

pub const ISwapChainPanelNative = extern struct {
    pub const IID = GUID{
        .Data1 = 0x63aad0b8,
        .Data2 = 0x7c24,
        .Data3 = 0x40ff,
        .Data4 = .{ 0x85, 0xa8, 0x64, 0x0d, 0x94, 0x4c, 0xc3, 0x25 },
    };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // ISwapChainPanelNative (slot 3)
        SetSwapChain: *const fn (*anyopaque, ?*anyopaque) callconv(.winapi) HRESULT,
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn setSwapChain(self: *ISwapChainPanelNative, swap_chain: ?*anyopaque) WinRTError!void {
        try hrCheck(self.lpVtbl.SetSwapChain(@ptrCast(self), swap_chain));
    }
};

// ============================================================================
// ITabView 窶・Microsoft.UI.Xaml.Controls.ITabView
// Generated from WinMD
// ============================================================================

pub const ITabView = extern struct {
    // WinMD: Microsoft.UI.Xaml.Controls.ITabView
    // Blob: 01 00 e1 09 b5 07 38 1d 1b 55 95 f4 47 32 b0 49 f6 a6 00 00
    pub const IID = GUID{ .Data1 = 0x07b509e1, .Data2 = 0x1d38, .Data3 = 0x551b, .Data4 = .{ 0x95, 0xf4, 0x47, 0x32, 0xb0, 0x49, 0xf6, 0xa6 } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // ITabView (slots 6-60)
        get_TabWidthMode: VtblPlaceholder, // 6
        put_TabWidthMode: VtblPlaceholder, // 7
        get_CloseButtonOverlayMode: VtblPlaceholder, // 8
        put_CloseButtonOverlayMode: VtblPlaceholder, // 9
        get_TabStripHeader: VtblPlaceholder, // 10
        put_TabStripHeader: VtblPlaceholder, // 11
        get_TabStripHeaderTemplate: VtblPlaceholder, // 12
        put_TabStripHeaderTemplate: VtblPlaceholder, // 13
        get_TabStripFooter: VtblPlaceholder, // 14
        put_TabStripFooter: VtblPlaceholder, // 15
        get_TabStripFooterTemplate: VtblPlaceholder, // 16
        put_TabStripFooterTemplate: VtblPlaceholder, // 17
        get_IsAddTabButtonVisible: VtblPlaceholder, // 18
        put_IsAddTabButtonVisible: VtblPlaceholder, // 19
        get_AddTabButtonCommand: VtblPlaceholder, // 20
        put_AddTabButtonCommand: VtblPlaceholder, // 21
        get_AddTabButtonCommandParameter: VtblPlaceholder, // 22
        put_AddTabButtonCommandParameter: VtblPlaceholder, // 23
        add_TabCloseRequested: *const fn (*anyopaque, *anyopaque, *i64) callconv(.winapi) HRESULT, // 24
        remove_TabCloseRequested: *const fn (*anyopaque, i64) callconv(.winapi) HRESULT, // 25
        add_TabDroppedOutside: VtblPlaceholder, // 26
        remove_TabDroppedOutside: VtblPlaceholder, // 27
        add_AddTabButtonClick: *const fn (*anyopaque, *anyopaque, *i64) callconv(.winapi) HRESULT, // 28
        remove_AddTabButtonClick: *const fn (*anyopaque, i64) callconv(.winapi) HRESULT, // 29
        add_TabItemsChanged: VtblPlaceholder, // 30
        remove_TabItemsChanged: VtblPlaceholder, // 31
        get_TabItemsSource: VtblPlaceholder, // 32
        put_TabItemsSource: VtblPlaceholder, // 33
        get_TabItems: *const fn (*anyopaque, *?*IVector) callconv(.winapi) HRESULT, // 34
        get_TabItemTemplate: VtblPlaceholder, // 35
        put_TabItemTemplate: VtblPlaceholder, // 36
        get_TabItemTemplateSelector: VtblPlaceholder, // 37
        put_TabItemTemplateSelector: VtblPlaceholder, // 38
        get_CanDragTabs: VtblPlaceholder, // 39
        put_CanDragTabs: VtblPlaceholder, // 40
        get_CanReorderTabs: VtblPlaceholder, // 41
        put_CanReorderTabs: VtblPlaceholder, // 42
        get_AllowDropTabs: VtblPlaceholder, // 43
        put_AllowDropTabs: VtblPlaceholder, // 44
        get_SelectedIndex: *const fn (*anyopaque, *i32) callconv(.winapi) HRESULT, // 45
        put_SelectedIndex: *const fn (*anyopaque, i32) callconv(.winapi) HRESULT, // 46
        get_SelectedItem: VtblPlaceholder, // 47
        put_SelectedItem: VtblPlaceholder, // 48
        ContainerFromItem: VtblPlaceholder, // 49
        ContainerFromIndex: VtblPlaceholder, // 50
        add_SelectionChanged: *const fn (*anyopaque, *anyopaque, *i64) callconv(.winapi) HRESULT, // 51
        remove_SelectionChanged: *const fn (*anyopaque, i64) callconv(.winapi) HRESULT, // 52
        add_TabDragStarting: VtblPlaceholder, // 53
        remove_TabDragStarting: VtblPlaceholder, // 54
        add_TabDragCompleted: VtblPlaceholder, // 55
        remove_TabDragCompleted: VtblPlaceholder, // 56
        add_TabStripDragOver: VtblPlaceholder, // 57
        remove_TabStripDragOver: VtblPlaceholder, // 58
        add_TabStripDrop: VtblPlaceholder, // 59
        remove_TabStripDrop: VtblPlaceholder, // 60
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn getTabItems(self: *ITabView) WinRTError!*IVector {
        var result: ?*IVector = null;
        try hrCheck(self.lpVtbl.get_TabItems(@ptrCast(self), &result));
        return result orelse error.WinRTFailed;
    }

    pub fn getSelectedIndex(self: *ITabView) WinRTError!i32 {
        var idx: i32 = 0;
        try hrCheck(self.lpVtbl.get_SelectedIndex(@ptrCast(self), &idx));
        return idx;
    }

    pub fn putSelectedIndex(self: *ITabView, idx: i32) WinRTError!void {
        try hrCheck(self.lpVtbl.put_SelectedIndex(@ptrCast(self), idx));
    }

    pub fn addTabCloseRequested(self: *ITabView, handler: *anyopaque) WinRTError!i64 {
        var token: i64 = 0;
        try hrCheck(self.lpVtbl.add_TabCloseRequested(@ptrCast(self), handler, &token));
        return token;
    }

    pub fn removeTabCloseRequested(self: *ITabView, token: i64) WinRTError!void {
        try hrCheck(self.lpVtbl.remove_TabCloseRequested(@ptrCast(self), token));
    }

    pub fn addAddTabButtonClick(self: *ITabView, handler: *anyopaque) WinRTError!i64 {
        var token: i64 = 0;
        try hrCheck(self.lpVtbl.add_AddTabButtonClick(@ptrCast(self), handler, &token));
        return token;
    }

    pub fn removeAddTabButtonClick(self: *ITabView, token: i64) WinRTError!void {
        try hrCheck(self.lpVtbl.remove_AddTabButtonClick(@ptrCast(self), token));
    }

    pub fn addSelectionChanged(self: *ITabView, handler: *anyopaque) WinRTError!i64 {
        var token: i64 = 0;
        try hrCheck(self.lpVtbl.add_SelectionChanged(@ptrCast(self), handler, &token));
        return token;
    }

    pub fn removeSelectionChanged(self: *ITabView, token: i64) WinRTError!void {
        try hrCheck(self.lpVtbl.remove_SelectionChanged(@ptrCast(self), token));
    }
};

// ============================================================================
// ITabViewItem 窶・Microsoft.UI.Xaml.Controls.ITabViewItem
// Generated from WinMD
// ============================================================================

pub const ITabViewItem = extern struct {
    // WinMD: Microsoft.UI.Xaml.Controls.ITabViewItem
    // Blob: 01 00 fa 0a 98 64 af 97 90 51 90 b3 4b a2 77 b1 11 3d 00 00
    pub const IID = GUID{ .Data1 = 0x64980afa, .Data2 = 0x97af, .Data3 = 0x5190, .Data4 = .{ 0x90, 0xb3, 0x4b, 0xa2, 0x77, 0xb1, 0x11, 0x3d } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // ITabViewItem (slots 6-16)
        get_Header: VtblPlaceholder, // 6
        put_Header: *const fn (*anyopaque, ?*anyopaque) callconv(.winapi) HRESULT, // 7
        get_HeaderTemplate: VtblPlaceholder, // 8
        put_HeaderTemplate: VtblPlaceholder, // 9
        get_IconSource: VtblPlaceholder, // 10
        put_IconSource: VtblPlaceholder, // 11
        get_IsClosable: VtblPlaceholder, // 12
        put_IsClosable: *const fn (*anyopaque, i32) callconv(.winapi) HRESULT, // 13
        get_TabViewTemplateSettings: VtblPlaceholder, // 14
        add_CloseRequested: VtblPlaceholder, // 15
        remove_CloseRequested: VtblPlaceholder, // 16
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn putHeader(self: *ITabViewItem, header: ?*anyopaque) WinRTError!void {
        try hrCheck(self.lpVtbl.put_Header(@ptrCast(self), header));
    }

    pub fn putIsClosable(self: *ITabViewItem, closable: bool) WinRTError!void {
        try hrCheck(self.lpVtbl.put_IsClosable(@ptrCast(self), @intFromBool(closable)));
    }
};

// ============================================================================
// IContentControl 窶・Microsoft.UI.Xaml.Controls.IContentControl
// Generated from WinMD
// ============================================================================

pub const IContentControl = extern struct {
    // WinMD: Microsoft.UI.Xaml.Controls.IContentControl
    // Blob: 01 00 61 17 e8 07 b2 11 ae 52 8f 8b 4d 53 d2 b5 90 0a 00 00
    pub const IID = GUID{ .Data1 = 0x07e81761, .Data2 = 0x11b2, .Data3 = 0x52ae, .Data4 = .{ 0x8f, 0x8b, 0x4d, 0x53, 0xd2, 0xb5, 0x90, 0x0a } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IContentControl (slots 6-14)
        get_Content: VtblPlaceholder, // 6
        put_Content: *const fn (*anyopaque, ?*anyopaque) callconv(.winapi) HRESULT, // 7
        get_ContentTemplate: VtblPlaceholder, // 8
        put_ContentTemplate: VtblPlaceholder, // 9
        get_ContentTemplateSelector: VtblPlaceholder, // 10
        put_ContentTemplateSelector: VtblPlaceholder, // 11
        get_ContentTransitions: VtblPlaceholder, // 12
        put_ContentTransitions: VtblPlaceholder, // 13
        get_ContentTemplateRoot: VtblPlaceholder, // 14
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn putContent(self: *IContentControl, content: ?*anyopaque) WinRTError!void {
        try hrCheck(self.lpVtbl.put_Content(@ptrCast(self), content));
    }
};

// ============================================================================
// IVector 窶・Windows.Foundation.Collections.IVector<IInspectable>
// IID: {B32BDCA4-5E52-5B27-BC5D-D66A1A268C2A} (pinterface computed)
// NOT from WinMD 窶・maintained manually
// ============================================================================

pub const IVector = extern struct {
    pub const IID = GUID{
        .Data1 = 0xb32bdca4,
        .Data2 = 0x5e52,
        .Data3 = 0x5b27,
        .Data4 = .{ 0xbc, 0x5d, 0xd6, 0x6a, 0x1a, 0x26, 0x8c, 0x2a },
    };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IVector<IInspectable> (slots 6-17)
        GetAt: *const fn (*anyopaque, u32, *?*anyopaque) callconv(.winapi) HRESULT, // 6
        get_Size: *const fn (*anyopaque, *u32) callconv(.winapi) HRESULT, // 7
        GetView: VtblPlaceholder, // 8
        IndexOf: VtblPlaceholder, // 9
        SetAt: VtblPlaceholder, // 10
        InsertAt: *const fn (*anyopaque, u32, ?*anyopaque) callconv(.winapi) HRESULT, // 11
        RemoveAt: *const fn (*anyopaque, u32) callconv(.winapi) HRESULT, // 12
        Append: *const fn (*anyopaque, ?*anyopaque) callconv(.winapi) HRESULT, // 13
        RemoveAtEnd: VtblPlaceholder, // 14
        Clear: VtblPlaceholder, // 15
        GetMany: VtblPlaceholder, // 16
        ReplaceAll: VtblPlaceholder, // 17
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn getAt(self: *IVector, index: u32) WinRTError!*anyopaque {
        var result: ?*anyopaque = null;
        try hrCheck(self.lpVtbl.GetAt(@ptrCast(self), index, &result));
        return result orelse error.WinRTFailed;
    }

    pub fn getSize(self: *IVector) WinRTError!u32 {
        var size: u32 = 0;
        try hrCheck(self.lpVtbl.get_Size(@ptrCast(self), &size));
        return size;
    }

    pub fn insertAt(self: *IVector, index: u32, item: ?*anyopaque) WinRTError!void {
        try hrCheck(self.lpVtbl.InsertAt(@ptrCast(self), index, item));
    }

    pub fn removeAt(self: *IVector, index: u32) WinRTError!void {
        try hrCheck(self.lpVtbl.RemoveAt(@ptrCast(self), index));
    }

    pub fn append(self: *IVector, item: ?*anyopaque) WinRTError!void {
        try hrCheck(self.lpVtbl.Append(@ptrCast(self), item));
    }
};

// ============================================================================
// IResourceDictionary 窶・Microsoft.UI.Xaml.IResourceDictionary
// Generated from WinMD
// ============================================================================

pub const IResourceDictionary = extern struct {
    // WinMD: Microsoft.UI.Xaml.IResourceDictionary
    // Blob: 01 00 75 09 69 1b 10 a7 83 57 a6 e1 15 83 6f 61 86 c2
    pub const IID = GUID{ .Data1 = 0x1b690975, .Data2 = 0xa710, .Data3 = 0x5783, .Data4 = .{ 0xa6, 0xe1, 0x15, 0x83, 0x6f, 0x61, 0x86, 0xc2 } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IResourceDictionary (slots 6-9)
        get_Source: VtblPlaceholder, // 6
        put_Source: VtblPlaceholder, // 7
        get_MergedDictionaries: *const fn (*anyopaque, *?*IVector) callconv(.winapi) HRESULT, // 8
        get_ThemeDictionaries: VtblPlaceholder, // 9
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    pub fn getMergedDictionaries(self: *IResourceDictionary) WinRTError!*IVector {
        var result: ?*IVector = null;
        try hrCheck(self.lpVtbl.get_MergedDictionaries(@ptrCast(self), &result));
        return result orelse error.WinRTFailed;
    }
};

// ============================================================================
// IXamlMetadataProvider 窶・Microsoft.UI.Xaml.Markup.IXamlMetadataProvider
// Generated from WinMD
// ============================================================================

pub const IXamlMetadataProvider = extern struct {
    // WinMD: Microsoft.UI.Xaml.Markup.IXamlMetadataProvider
    // Blob: 01 00 f0 51 62 a9 14 22 53 5d 87 46 ce 99 a2 59 3c d7
    pub const IID = GUID{ .Data1 = 0xa96251f0, .Data2 = 0x2214, .Data3 = 0x5d53, .Data4 = .{ 0x87, 0x46, 0xce, 0x99, 0xa2, 0x59, 0x3c, 0xd7 } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IXamlMetadataProvider (slots 6-8)
        GetXamlType: *const fn (*anyopaque, [*]const u8, *?*anyopaque) callconv(.winapi) HRESULT, // 6 (TypeName)
        GetXamlType_2: *const fn (*anyopaque, ?HSTRING, *?*anyopaque) callconv(.winapi) HRESULT, // 7 (hstring)
        GetXmlnsDefinitions: *const fn (*anyopaque, *u32, *?[*]*anyopaque) callconv(.winapi) HRESULT, // 8
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    /// Call GetXamlType(fullName) 竊・IXamlType (slot 7).
    pub fn getXamlType(self: *IXamlMetadataProvider, full_name: ?HSTRING) WinRTError!*IXamlType {
        var result: ?*anyopaque = null;
        try hrCheck(self.lpVtbl.GetXamlType_2(@ptrCast(self), full_name, &result));
        return @ptrCast(@alignCast(result orelse return error.WinRTFailed));
    }
};

// ============================================================================
// IXamlType 窶・Microsoft.UI.Xaml.Markup.IXamlType
// Used to activate WinUI3 custom controls via XAML type system instead of
// RoActivateInstance (which returns E_NOTIMPL for controls like TabView).
// ============================================================================

pub const IXamlType = extern struct {
    // WinMD: Microsoft.UI.Xaml.Markup.IXamlType
    // Blob: 01 00 df 19 42 d2 c9 7e f1 57 a2 7b 6a f2 51 d9 c5 bc 00 00
    pub const IID = GUID{ .Data1 = 0xd24219df, .Data2 = 0x7ec9, .Data3 = 0x57f1,
        .Data4 = .{ 0xa2, 0x7b, 0x6a, 0xf2, 0x51, 0xd9, 0xc5, 0xbc } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IXamlType (slots 6-24) 窶・generated by winmd2zig
        get_BaseType: VtblPlaceholder, // 6
        get_ContentProperty: VtblPlaceholder, // 7
        get_FullName: VtblPlaceholder, // 8
        get_IsArray: VtblPlaceholder, // 9
        get_IsCollection: VtblPlaceholder, // 10
        get_IsConstructible: VtblPlaceholder, // 11
        get_IsDictionary: VtblPlaceholder, // 12
        get_IsMarkupExtension: VtblPlaceholder, // 13
        get_IsBindable: VtblPlaceholder, // 14
        get_ItemType: VtblPlaceholder, // 15
        get_KeyType: VtblPlaceholder, // 16
        get_BoxedType: VtblPlaceholder, // 17
        get_UnderlyingType: VtblPlaceholder, // 18
        ActivateInstance: *const fn (*anyopaque, *?*anyopaque) callconv(.winapi) HRESULT, // 19
        CreateFromString: VtblPlaceholder, // 20
        GetMember: VtblPlaceholder, // 21
        AddToVector: VtblPlaceholder, // 22
        AddToMap: VtblPlaceholder, // 23
        RunInitializer: VtblPlaceholder, // 24
    };

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }

    /// Create an instance of this XAML type.
    pub fn activateInstance(self: *IXamlType) WinRTError!*IInspectable {
        var result: ?*anyopaque = null;
        try hrCheck(self.lpVtbl.ActivateInstance(@ptrCast(self), &result));
        return @ptrCast(@alignCast(result orelse return error.WinRTFailed));
    }
};

// ============================================================================
// IApplicationOverrides 窶・Microsoft.UI.Xaml.IApplicationOverrides
// Generated from WinMD
// ============================================================================

pub const IApplicationOverrides = extern struct {
    // WinMD: Microsoft.UI.Xaml.IApplicationOverrides
    // Blob: 01 00 ef 81 3e a3 65 c6 3b 50 88 27 d2 7e f1 72 0a 06
    pub const IID = GUID{ .Data1 = 0xa33e81ef, .Data2 = 0xc665, .Data3 = 0x503b, .Data4 = .{ 0x88, 0x27, 0xd2, 0x7e, 0xf1, 0x72, 0x0a, 0x06 } };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IApplicationOverrides (slots 6-6)
        OnLaunched: *const fn (*anyopaque, ?*anyopaque) callconv(.winapi) HRESULT, // 6
    };

    pub fn release(self: *IApplicationOverrides) void {
        _ = self.lpVtbl.Release(@ptrCast(self));
    }
};

// ============================================================================
// IPropertyValueStatics 窶・Windows.Foundation.IPropertyValueStatics
// NOT from WinMD 窶・maintained manually (Windows SDK, not WinUI3 SDK)
// Used for boxing primitive values (strings, ints, etc.) as IInspectable.
// ============================================================================

pub const IPropertyValueStatics = extern struct {
    pub const IID = GUID{
        .Data1 = 0x629bdbc8,
        .Data2 = 0xd932,
        .Data3 = 0x4ff4,
        .Data4 = .{ 0x96, 0xb9, 0x8d, 0x96, 0xc5, 0xc1, 0xe8, 0x58 },
    };

    lpVtbl: *const VTable,

    const VTable = extern struct {
        // IUnknown (slots 0-2)
        QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) u32,
        Release: *const fn (*anyopaque) callconv(.winapi) u32,
        // IInspectable (slots 3-5)
        GetIids: VtblPlaceholder,
        GetRuntimeClassName: VtblPlaceholder,
        GetTrustLevel: VtblPlaceholder,
        // IPropertyValueStatics (slots 6-25)
        CreateEmpty: VtblPlaceholder, // 6
        CreateUInt8: VtblPlaceholder, // 7
        CreateInt16: VtblPlaceholder, // 8
        CreateUInt16: VtblPlaceholder, // 9
        CreateInt32: VtblPlaceholder, // 10
        CreateUInt32: VtblPlaceholder, // 11
        CreateInt64: VtblPlaceholder, // 12
        CreateUInt64: VtblPlaceholder, // 13
        CreateSingle: VtblPlaceholder, // 14
        CreateDouble: VtblPlaceholder, // 15
        CreateChar16: VtblPlaceholder, // 16
        CreateBoolean: VtblPlaceholder, // 17
        CreateString: *const fn (*anyopaque, ?HSTRING, *?*IInspectable) callconv(.winapi) HRESULT, // 18
        CreateInspectable: VtblPlaceholder, // 19
        CreateGuid: VtblPlaceholder, // 20
        CreateDateTime: VtblPlaceholder, // 21
        CreateTimeSpan: VtblPlaceholder, // 22
        CreatePoint: VtblPlaceholder, // 23
        CreateSize: VtblPlaceholder, // 24
        CreateRect: VtblPlaceholder, // 25
    };

    pub fn createString(self: *IPropertyValueStatics, value: ?HSTRING) WinRTError!*IInspectable {
        var result: ?*IInspectable = null;
        try hrCheck(self.lpVtbl.CreateString(@ptrCast(self), value, &result));
        return result orelse error.WinRTFailed;
    }

    pub fn release(self: *@This()) void { comRelease(self); }
    pub fn queryInterface(self: *@This(), comptime T: type) WinRTError!*T { return comQueryInterface(self, T); }
};

// ============================================================================
// Common COM helpers 窶・reduce release/queryInterface boilerplate
// ============================================================================

/// Release a COM object. Works with any interface struct that has lpVtbl.Release.
pub inline fn comRelease(self: anytype) void {
    _ = self.lpVtbl.Release(@ptrCast(self));
}

/// QueryInterface on any COM object. Works with any interface struct that has lpVtbl.QueryInterface.
pub inline fn comQueryInterface(self: anytype, comptime T: type) WinRTError!*T {
    var result: ?*anyopaque = null;
    try hrCheck(self.lpVtbl.QueryInterface(@ptrCast(self), &T.IID, &result));
    return @ptrCast(@alignCast(result orelse return error.WinRTFailed));
}

// ============================================================================
// TypedEventHandler delegate IIDs (parameterized)
//
// WinRT delegates are COM objects with IUnknown + Invoke.
// The framework QIs for the specific delegate IID before calling Invoke.
// These IIDs are computed from WinMD by winmd2zig --emit-tabview-delegate-zig.
// Verified against windows-rs shadow parity (28/28 IID match, 0 fail).
// ============================================================================

/// TypedEventHandler<TabView, TabViewTabCloseRequestedEventArgs>
/// Generated: winmd2zig --emit-tabview-delegate-zig Microsoft.UI.Xaml.winmd
pub const IID_TypedEventHandler_TabCloseRequested = GUID{ .Data1 = 0x7093974b, .Data2 = 0x0900, .Data3 = 0x52ae, .Data4 = .{ 0xaf, 0xd8, 0x70, 0xe5, 0x62, 0x3f, 0x45, 0x95 } };

/// TypedEventHandler<TabView, Object> (AddTabButtonClick)
/// Generated: winmd2zig --emit-tabview-delegate-zig Microsoft.UI.Xaml.winmd
pub const IID_TypedEventHandler_AddTabButtonClick = GUID{ .Data1 = 0x13df6907, .Data2 = 0xbbb4, .Data3 = 0x5f16, .Data4 = .{ 0xbe, 0xac, 0x29, 0x38, 0xc1, 0x5e, 0x1d, 0x85 } };

/// SelectionChangedEventHandler
/// Generated: winmd2zig --emit-tabview-delegate-zig Microsoft.UI.Xaml.winmd
pub const IID_SelectionChangedEventHandler = GUID{ .Data1 = 0xa232390d, .Data2 = 0x0e34, .Data3 = 0x595e, .Data4 = .{ 0x89, 0x31, 0xfa, 0x92, 0x8a, 0x99, 0x09, 0xf4 } };

