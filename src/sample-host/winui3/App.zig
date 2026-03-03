/// WinUI 3 application runtime for Ghostty.
///
/// Phase 3: Bootstraps Windows App SDK, initializes WinRT, creates a
/// WinUI 3 Window with HWND subclass message routing, creates a TabView
/// for multi-tab management, and routes input to the active Surface.
const App = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const windows = std.os.windows;
const build_config = @import("../../build_config.zig");
const apprt = @import("../../apprt.zig");
const CoreApp = @import("../../App.zig");
const CoreSurface = @import("../../Surface.zig");
const configpkg = @import("../../config.zig");
const input = @import("../../input.zig");
const Surface = @import("Surface.zig");
const key = @import("key.zig");
const winrt = @import("winrt.zig");
const bootstrap = @import("bootstrap.zig");
const com = @import("com.zig");
const event = @import("event.zig");
const os = @import("os.zig");
const com_aggregation = @import("com_aggregation.zig");
const input_overlay = @import("input_overlay.zig");
const ime = @import("ime.zig");
const debug_harness = @import("debug_harness.zig");

const log = std.log.scoped(.winui3);

/// Timer ID for live resize preview.
const RESIZE_TIMER_ID: usize = 1;

const InitCallback = com_aggregation.InitCallback;
const AppOuter = com_aggregation.AppOuter;
const guidEql = com_aggregation.guidEql;

/// The core application.
core_app: *CoreApp,
debug_cfg: debug_harness.RuntimeDebugConfig = .{},

/// COM aggregation outer object that implements IXamlMetadataProvider.
/// Must be kept alive for the lifetime of the Application.
app_outer: AppOuter = undefined,

/// The WinUI 3 Application instance (needed for calling Exit() on shutdown).
xaml_app: ?*com.IApplication = null,

/// The WinUI 3 Window.
window: ?*com.IWindow = null,

/// The native HWND obtained from IWindowNative.
hwnd: ?os.HWND = null,
root_hwnd: ?os.HWND = null,

/// The child HWND created by WinUI3 for the content area (DesktopChildSiteBridge).
child_hwnd: ?os.HWND = null,

/// Our own input HWND — a transparent child window that receives keyboard focus
/// and all IME messages, bypassing WinUI3's TSF layer entirely.
input_hwnd: ?os.HWND = null,

/// All surfaces (one per tab).
surfaces: std.ArrayList(*Surface),

/// Index of the currently active/selected tab.
active_surface_idx: usize = 0,

/// The TabView control that manages tabs.
tab_view: ?*com.ITabView = null,

/// Whether the app is running.
running: bool = false,

/// Whether the user is currently in a modal resize/move loop.
/// Set by WM_ENTERSIZEMOVE / WM_EXITSIZEMOVE.
resizing: bool = false,

/// Pending size from WM_SIZE during modal resize. Applied on WM_EXITSIZEMOVE.
pending_size: ?struct { width: u32, height: u32 } = null,

/// Fullscreen state.
is_fullscreen: bool = false,
saved_style: usize = 0,
saved_placement: os.WINDOWPLACEMENT = .{},

/// Closed event handler (prevent dangling reference).
closed_handler: ?*event.SimpleEventHandler(App) = null,
closed_token: ?i64 = null,

/// TabView event handlers.
tab_close_handler: ?*event.SimpleEventHandler(App) = null,
add_tab_handler: ?*event.SimpleEventHandler(App) = null,
selection_changed_handler: ?*event.SimpleEventHandler(App) = null,
tab_close_token: ?i64 = null,
add_tab_token: ?i64 = null,
selection_changed_token: ?i64 = null,

pub fn init(
    self: *App,
    core_app: *CoreApp,
    opts: struct {},
) !void {
    _ = opts;

    // Allocate a debug console so log output is visible for GUI apps.
    os.attachDebugConsole();

    // Install a Vectored Exception Handler to capture details of
    // STATUS_STOWED_EXCEPTION before the process terminates.
    _ = os.AddVectoredExceptionHandler(1, &stowedExceptionHandler);

    // Request 1ms timer resolution for smooth animation timing.
    _ = os.timeBeginPeriod(1);

    // Step 1: Bootstrap the Windows App SDK runtime.
    bootstrap.init() catch |err| {
        log.err("Windows App SDK bootstrap failed: {}", .{err});
        return error.AppInitFailed;
    };

    // Step 2: Initialize WinRT.
    winrt.hrCheck(winrt.RoInitialize(winrt.RO_INIT_SINGLETHREADED)) catch |err| {
        log.err("RoInitialize failed: {}", .{err});
        return error.AppInitFailed;
    };

    // Step 3: Create a DispatcherQueue for the current thread.
    // This is required before creating any XAML objects.
    const dq_opts = winrt.DispatcherQueueOptions{};
    const dq_controller = winrt.createDispatcherQueueController(&dq_opts) catch |err| {
        log.err("CreateDispatcherQueueController failed: {}", .{err});
        return error.AppInitFailed;
    };
    _ = dq_controller;

    self.* = .{
        .core_app = core_app,
        .debug_cfg = debug_harness.RuntimeDebugConfig.load(),
        .surfaces = .{},
        .running = true,
    };
    self.debug_cfg.log(log);

    // Window/UI creation happens inside run() via Application.Start(callback).
    // WinUI 3 requires Window creation on the XAML thread which is set up by Start().
    log.info("WinUI 3 runtime initialized (window creation deferred to run)", .{});
}

/// Called from inside Application.Start() callback — XAML thread is active here.
pub fn initXaml(self: *App) !void {
    log.info("initXaml: creating Window inside XAML thread", .{});

    // Step 0: Create the Application instance via IApplicationFactory with COM aggregation.
    // Application.Start() does NOT create an Application — the callback must.
    //
    // WinUI 3 custom controls (TabView, etc.) require IXamlMetadataProvider to be
    // implemented on the Application object. We use COM aggregation to inject our
    // implementation: AppOuter acts as the controlling IUnknown, and when the XAML
    // framework QI's for IXamlMetadataProvider, it gets our implementation which
    // delegates to XamlControlsXamlMetaDataProvider.
    const app_class = try winrt.hstring("Microsoft.UI.Xaml.Application");
    defer winrt.deleteHString(app_class);
    log.info("initXaml step 0: Creating Application with COM aggregation...", .{});

    // Initialize the outer object that implements IXamlMetadataProvider.
    self.app_outer.init();

    // Activate XamlControlsXamlMetaDataProvider for metadata delegation.
    const provider_class = winrt.hstring("Microsoft.UI.Xaml.XamlTypeInfo.XamlControlsXamlMetaDataProvider") catch null;
    if (provider_class) |pc| {
        defer winrt.deleteHString(pc);
        const provider_inspectable = winrt.activateInstance(pc) catch |err| blk: {
            log.warn("XamlControlsXamlMetaDataProvider activation failed: {}", .{err});
            break :blk null;
        };
        if (provider_inspectable) |pi| {
            self.app_outer.provider = pi.queryInterface(com.IXamlMetadataProvider) catch null;
            if (self.app_outer.provider != null) {
                log.info("initXaml step 0: XamlControlsXamlMetaDataProvider OK", .{});
            }
        }
    }

    // Create Application with outer IUnknown for aggregation.
    log.info("initXaml step 0: getActivationFactory(IApplicationFactory)...", .{});
    const app_factory = try winrt.getActivationFactory(com.IApplicationFactory, app_class);
    defer app_factory.release();
    log.info("initXaml step 0: calling CreateInstance(outer=0x{x})...", .{@intFromPtr(self.app_outer.outerPtr())});
    const result = try app_factory.createInstance(self.app_outer.outerPtr());
    log.info("initXaml step 0: CreateInstance returned inner=0x{x} instance=0x{x}", .{
        @intFromPtr(result.inner), @intFromPtr(result.instance),
    });
    self.app_outer.inner = result.inner;

    // QI for IApplication so we can call Exit() during shutdown and access Resources.
    self.xaml_app = result.instance.queryInterface(com.IApplication) catch null;
    log.info("initXaml step 0 OK: Application created with IXamlMetadataProvider", .{});

    // Step 1: Create a Window via RoActivateInstance.
    const window_class = try winrt.hstring("Microsoft.UI.Xaml.Window");
    defer winrt.deleteHString(window_class);
    log.info("initXaml step 1: RoActivateInstance(Window)...", .{});
    const window_inspectable = try winrt.activateInstance(window_class);
    log.info("initXaml step 1 OK: got IInspectable @ 0x{x}", .{@intFromPtr(window_inspectable)});

    // Step 2: QI for IWindow.
    log.info("initXaml step 2: QueryInterface(IWindow)...", .{});
    const window = try window_inspectable.queryInterface(com.IWindow);
    self.window = window;
    log.info("initXaml step 2 OK: IWindow @ 0x{x}", .{@intFromPtr(window)});

    // Step 3: Set the window title.
    const title = try winrt.hstring("Ghostty");
    defer winrt.deleteHString(title);
    log.info("initXaml step 3: putTitle...", .{});
    try window.putTitle(title);
    log.info("initXaml step 3 OK", .{});

    // Step 4: Get the native HWND via IWindowNative.
    log.info("initXaml step 4: QueryInterface(IWindowNative)...", .{});
    const window_native = try window.queryInterface(com.IWindowNative);
    defer window_native.release();
    self.hwnd = try window_native.getWindowHandle();
    log.info("initXaml step 4 OK: HWND=0x{x}", .{@intFromPtr(self.hwnd.?)});

    // Also track root owner window; close messages are often dispatched there.
    self.root_hwnd = os.GetAncestor(self.hwnd.?, os.GA_ROOT) orelse self.hwnd.?;

    // Step 5: Install subclass on the HWND.
    log.info("initXaml step 5: SetWindowSubclass...", .{});
    _ = os.SetWindowSubclass(self.hwnd.?, &subclassProc, 0, @intFromPtr(self));
    if (self.root_hwnd) |root| {
        if (root != self.hwnd.?) _ = os.SetWindowSubclass(root, &subclassProc, 1, @intFromPtr(self));
    }
    log.info("initXaml step 5 OK", .{});

    // Step 6: Register Closed event handler.
    log.info("initXaml step 6: addClosed handler...", .{});
    const alloc = self.core_app.alloc;
    self.closed_handler = try event.SimpleEventHandler(App).create(alloc, self, &onWindowClosed);
    self.closed_token = try window.addClosed(self.closed_handler.?.comPtr());
    log.info("initXaml step 6 OK", .{});

    // Step 7: Activate the window (makes it visible).
    log.info("initXaml step 7: Activate...", .{});
    try window.activate();
    log.info("initXaml step 7 OK: Window activated!", .{});

    // Step 7.25: Load XamlControlsResources into Application.Resources.
    // Must be done AFTER Window creation/activation — the Application's Resources
    // property returns E_UNEXPECTED before the XAML framework is fully initialized.
    if (self.debug_cfg.enable_xaml_resources) {
        if (self.xaml_app) |xa| {
            loadXamlResources(xa);
        }
    } else {
        log.info("initXaml step 7.25: SKIPPED (GHOSTTY_WINUI3_ENABLE_XAML_RESOURCES=false)", .{});
    }

    // Step 7.5: Create TabView and set as Window content.
    // WinUI3 custom controls need XAML type system activation (IXamlType.ActivateInstance).
    // RoActivateInstance returns E_NOTIMPL for these controls.
    const tab_view: ?*com.ITabView = if (self.debug_cfg.enable_tabview) blk: {
        log.info("initXaml step 7.5: Creating TabView via XAML type system...", .{});
        const tv_inspectable = self.activateXamlType("Microsoft.UI.Xaml.Controls.TabView") catch |err| {
            log.warn("TabView creation failed ({}), falling back to single-tab mode", .{err});
            break :blk null;
        };
        const tv = tv_inspectable.queryInterface(com.ITabView) catch |err| {
            log.warn("TabView QI for ITabView failed ({}), falling back to single-tab mode", .{err});
            break :blk null;
        };
        window.putContent(@ptrCast(tv_inspectable)) catch |err| {
            log.warn("TabView putContent failed ({}), falling back to single-tab mode", .{err});
            tv.release();
            break :blk null;
        };
        log.info("initXaml step 7.5 OK: TabView set as Window content", .{});
        break :blk tv;
    } else blk: {
        log.info("initXaml step 7.5: SKIPPED (GHOSTTY_WINUI3_ENABLE_TABVIEW=false)", .{});
        break :blk null;
    };
    self.tab_view = tab_view;

    // Step 8: Create the initial Surface (terminal) inside a TabViewItem.
    if (self.debug_cfg.tabview_empty and tab_view != null) {
        log.info("initXaml step 8: SKIPPED (GHOSTTY_WINUI3_TABVIEW_EMPTY=true)", .{});
    } else {
    log.info("initXaml step 8: Creating initial Surface...", .{});
    var config = try configpkg.Config.load(alloc);
    defer config.deinit();

    var surface = try alloc.create(Surface);
    errdefer alloc.destroy(surface);
    try surface.init(self, self.core_app, &config);
    errdefer surface.deinit();

    try self.surfaces.append(alloc, surface);

    // Set the Surface's SwapChainPanel as content.
    if (surface.swap_chain_panel) |panel| {
        if (tab_view) |tv| {
            // TabView mode: wrap in TabViewItem.
            const tvi_inspectable = try self.activateXamlType("Microsoft.UI.Xaml.Controls.TabViewItem");
            const tvi = try tvi_inspectable.queryInterface(com.ITabViewItem);
            defer tvi.release();

            // Match the reference setup: initialize basic TabViewItem properties
            // before appending it to TabView.
            const initial_title = try winrt.hstring("Terminal");
            defer winrt.deleteHString(initial_title);
            const boxed_title = try self.boxString(initial_title);
            defer _ = boxed_title.release();
            try tvi.putHeader(@ptrCast(boxed_title));
            try tvi.putIsClosable(false);

            if (!self.debug_cfg.tabview_item_no_content) {
                const content_control = try tvi_inspectable.queryInterface(com.IContentControl);
                defer content_control.release();
                try content_control.putContent(@ptrCast(panel));
                log.info("initXaml step 8: putContent done", .{});
            } else {
                log.info("initXaml step 8: SKIPPING putContent (GHOSTTY_WINUI3_TABVIEW_ITEM_NO_CONTENT=true)", .{});
            }

            if (!self.debug_cfg.tabview_append_item) {
                log.info("initXaml step 8: STOP at level 1 (create+putContent only, no append)", .{});
            } else {
                const tab_items = try tv.getTabItems();
                try tab_items.append(@ptrCast(tvi_inspectable));
                log.info("initXaml step 8: append done", .{});

                surface.tab_view_item_inspectable = tvi_inspectable;

                if (!self.debug_cfg.tabview_select_first) {
                    log.info("initXaml step 8: STOP at level 2 (create+putContent+append, no selectedIndex)", .{});
                } else {
                    try tv.putSelectedIndex(0);
                    log.info("initXaml step 8 OK: full (create+putContent+append+selectedIndex)", .{});
                }
            }
        } else {
            // Fallback: set SwapChainPanel directly as Window content.
            try window.putContent(@ptrCast(panel));
            log.info("initXaml step 8 OK: Surface + SwapChainPanel set as Window content (single-tab)", .{});
        }
    }
    } // end TABVIEW_EMPTY else

    // Step 8.5: Register TabView event handlers after control tree creation.
    // Register TabView event handlers (only if TabView was created).
    if (tab_view != null and self.debug_cfg.enable_tabview_handlers) {
        if (self.debug_cfg.enable_handler_close) {
            self.tab_close_handler = try event.SimpleEventHandler(App).createWithIid(alloc, self, &onTabCloseRequested, &com.IID_TypedEventHandler_TabCloseRequested);
            self.tab_close_token = try tab_view.?.addTabCloseRequested(self.tab_close_handler.?.comPtr());
            log.info("initXaml step 7.5: TabCloseRequested handler registered", .{});
        }
        if (self.debug_cfg.enable_handler_addtab) {
            self.add_tab_handler = try event.SimpleEventHandler(App).createWithIid(alloc, self, &onAddTabButtonClick, &com.IID_TypedEventHandler_AddTabButtonClick);
            self.add_tab_token = try tab_view.?.addAddTabButtonClick(self.add_tab_handler.?.comPtr());
            log.info("initXaml step 7.5: AddTabButtonClick handler registered", .{});
        }
        if (self.debug_cfg.enable_handler_selection) {
            self.selection_changed_handler = try event.SimpleEventHandler(App).createWithIid(alloc, self, &onSelectionChanged, &com.IID_SelectionChangedEventHandler);
            self.selection_changed_token = try tab_view.?.addSelectionChanged(self.selection_changed_handler.?.comPtr());
            log.info("initXaml step 7.5: SelectionChanged handler registered", .{});
        }
        log.info("initXaml step 7.5 OK: TabView event handlers registered (close={} addtab={} selection={})", .{
            self.debug_cfg.enable_handler_close,
            self.debug_cfg.enable_handler_addtab,
            self.debug_cfg.enable_handler_selection,
        });
    } else if (tab_view != null) {
        log.info("initXaml step 7.5: TabView event handlers SKIPPED (GHOSTTY_WINUI3_ENABLE_TABVIEW_HANDLERS=false)", .{});
    }



    log.info("WinUI 3 Window created and activated (HWND=0x{x})", .{@intFromPtr(self.hwnd.?)});

    // Step 9: Find the WinUI3 child HWND (DesktopChildSiteBridge) for reference,
    // and create our own input HWND that sits on top for keyboard/IME focus.
    //
    // WinUI3's child HWND uses TSF (Text Services Framework) internally.
    // Subclassing it for IME doesn't work because TSF intercepts IME messages
    // at a higher level. Instead, we create a dedicated transparent child HWND
    // with a standard Win32 wndproc that receives all keyboard and IME messages
    // directly, completely bypassing WinUI3's input stack.
    const child = os.GetWindow(self.hwnd.?, os.GW_CHILD);
    if (child) |child_hwnd| {
        self.child_hwnd = child_hwnd;
        log.info("initXaml step 9: found WinUI3 child HWND=0x{x}", .{@intFromPtr(child_hwnd)});
    }

    // Create our input overlay HWND.
    self.input_hwnd = input_overlay.createInputWindow(self.hwnd.?, @intFromPtr(self));
    if (self.input_hwnd) |input_hwnd| {
        // Enable IME on our input HWND.
        _ = os.ImmAssociateContextEx(input_hwnd, null, os.IACE_DEFAULT);
        // Give it initial focus.
        _ = os.SetFocus(input_hwnd);
        log.info("initXaml step 9 OK: input HWND=0x{x} created + IME enabled", .{@intFromPtr(input_hwnd)});
    } else {
        log.warn("initXaml step 9: failed to create input HWND, falling back to child subclass", .{});
        // Fallback: subclass the child HWND directly (IME may not work).
        if (self.child_hwnd) |chw| {
            _ = os.SetWindowSubclass(chw, &subclassProc, 0, @intFromPtr(self));
            _ = os.ImmAssociateContextEx(chw, null, os.IACE_DEFAULT);
        }
    }
}

/// Closed event callback — triggered when the user closes the window.
fn onWindowClosed(self: *App, _: *anyopaque, _: *anyopaque) void {
    // Tear down window hooks immediately on close event to avoid re-entrancy
    // with WinUI/XAML shutdown internals.
    if (self.input_hwnd) |input_hwnd| {
        _ = os.DestroyWindow(input_hwnd);
        self.input_hwnd = null;
    }
    if (self.child_hwnd) |child_hwnd| {
        _ = os.RemoveWindowSubclass(child_hwnd, &subclassProc, 0);
        self.child_hwnd = null;
    }
    if (self.root_hwnd) |root| {
        _ = os.RemoveWindowSubclass(root, &subclassProc, 1);
        self.root_hwnd = null;
    }
    if (self.hwnd) |hwnd| {
        _ = os.RemoveWindowSubclass(hwnd, &subclassProc, 0);
    }

    self.running = false;
    // Exit the XAML message loop so Application.Start() returns cleanly.
    if (self.xaml_app) |xa| {
        xa.exit() catch {};
    }
}

/// D3D11 doesn't use GL context — no-op for WinUI 3.
pub fn releaseGLContext(_: *App) void {}

/// D3D11 doesn't use GL context — no-op for WinUI 3.
pub fn makeGLContextCurrent(_: *App) !void {}

pub fn run(self: *App) !void {
    // Get Application statics to call Start().
    const app_class = try winrt.hstring("Microsoft.UI.Xaml.Application");
    defer winrt.deleteHString(app_class);
    const statics = try winrt.getActivationFactory(com.IApplicationStatics, app_class);
    defer statics.release();

    // Create the initialization callback (stack-allocated, used synchronously by Start).
    var callback = InitCallback.create(self);

    // Application.Start() calls our callback to create the Window,
    // then enters the XAML message loop. It blocks until the app exits.
    log.info("Calling Application.Start()...", .{});
    try statics.start(callback.comPtr());
    log.info("Application.Start() returned", .{});
}

pub fn terminate(self: *App) void {
    // Step 1: Destroy/remove input HWND and subclasses FIRST.
    // This prevents any further window messages from routing to our
    // handlers, which reference surfaces that we are about to free.
    if (self.input_hwnd) |input_hwnd| {
        _ = os.DestroyWindow(input_hwnd);
        self.input_hwnd = null;
    }
    if (self.child_hwnd) |child_hwnd| {
        _ = os.RemoveWindowSubclass(child_hwnd, &subclassProc, 0);
        self.child_hwnd = null;
    }
    if (self.root_hwnd) |root| {
        _ = os.RemoveWindowSubclass(root, &subclassProc, 1);
        self.root_hwnd = null;
    }
    if (self.hwnd) |hwnd| {
        _ = os.RemoveWindowSubclass(hwnd, &subclassProc, 0);
    }

    // Step 2: Close all remaining surfaces.
    // Surface.deinit() stops renderer and IO threads (joins them) before
    // freeing surface data, so this is safe after subclass removal.
    for (self.surfaces.items) |surface| {
        surface.deinit();
        self.core_app.alloc.destroy(surface);
    }
    self.surfaces.deinit(self.core_app.alloc);

    // Step 3: Unregister WinRT event handlers before freeing callback objects.
    if (self.tab_view) |tv| {
        if (self.tab_close_token) |tok| tv.removeTabCloseRequested(tok) catch {};
        if (self.add_tab_token) |tok| tv.removeAddTabButtonClick(tok) catch {};
        if (self.selection_changed_token) |tok| tv.removeSelectionChanged(tok) catch {};
    }
    if (self.window) |window| {
        if (self.closed_token) |tok| window.removeClosed(tok) catch {};
    }
    self.tab_close_token = null;
    self.add_tab_token = null;
    self.selection_changed_token = null;
    self.closed_token = null;

    // Step 4: Free callback wrapper objects after unregistration.
    if (self.closed_handler) |handler| self.core_app.alloc.destroy(handler);
    if (self.tab_close_handler) |handler| self.core_app.alloc.destroy(handler);
    if (self.add_tab_handler) |handler| self.core_app.alloc.destroy(handler);
    if (self.selection_changed_handler) |handler| self.core_app.alloc.destroy(handler);
    self.closed_handler = null;
    self.tab_close_handler = null;
    self.add_tab_handler = null;
    self.selection_changed_handler = null;

    // Step 5: Release WinRT/XAML objects.
    if (self.tab_view) |tv| tv.release();
    if (self.window) |window| window.release();
    if (self.xaml_app) |xa| xa.release();
    // Release COM aggregation resources.
    if (self.app_outer.provider) |provider| provider.release();
    self.app_outer.provider = null;
    // Note: inner is released by the Application itself during shutdown.
    self.tab_view = null;
    self.window = null;
    self.xaml_app = null;
    self.hwnd = null;
    self.child_hwnd = null;

    // Step 6: Shutdown WinRT and Windows App SDK.
    winrt.RoUninitialize();
    bootstrap.deinit();

    _ = os.timeEndPeriod(1);

    log.info("WinUI 3 application terminated", .{});
}

/// Thread-safe wakeup: any thread can call this to unblock the event loop.
pub fn wakeup(self: *App) void {
    if (self.hwnd) |hwnd| {
        _ = os.PostMessageW(hwnd, os.WM_USER, 0, 0);
    }
}

pub fn performAction(
    self: *App,
    target: apprt.Target,
    comptime action: apprt.Action.Key,
    value: apprt.Action.Value(action),
) !bool {
    _ = target;

    switch (action) {
        .quit => {
            self.running = false;
            if (self.xaml_app) |xa| {
                xa.exit() catch {};
            }
            return true;
        },
        .new_window => {
            // MVP: single window only
            return false;
        },
        .close_all_windows => {
            self.running = false;
            if (self.xaml_app) |xa| {
                xa.exit() catch {};
            }
            return true;
        },
        .new_tab => {
            self.newTab() catch |err| {
                log.err("Failed to create new tab: {}", .{err});
                return false;
            };
            return true;
        },
        .close_tab => {
            self.closeActiveTab();
            return true;
        },
        .goto_tab => {
            if (self.tab_view) |tv| {
                const tab_count = self.surfaces.items.len;
                if (tab_count == 0) return true;
                const new_idx: usize = switch (value) {
                    .previous => if (self.active_surface_idx > 0) self.active_surface_idx - 1 else tab_count - 1,
                    .next => if (self.active_surface_idx + 1 < tab_count) self.active_surface_idx + 1 else 0,
                    .last => tab_count - 1,
                    _ => @min(@as(usize, @intCast(@intFromEnum(value))), tab_count - 1),
                };
                tv.putSelectedIndex(@intCast(new_idx)) catch {};
                self.active_surface_idx = new_idx;
            }
            return true;
        },
        .set_title => {
            log.info("performAction: set_title", .{});
            self.setTitle(value.title);
            return true;
        },
        .toggle_fullscreen => {
            self.toggleFullscreen();
            return true;
        },
        else => return false,
    }
}

pub fn performIpc(
    _: Allocator,
    _: apprt.ipc.Target,
    comptime action: apprt.ipc.Action.Key,
    _: apprt.ipc.Action.Value(action),
) !bool {
    return false;
}

pub fn redrawInspector(_: *App, _: *Surface) void {}

// ---------------------------------------------------------------
// Tab management
// ---------------------------------------------------------------

/// Create a new tab with a fresh Surface.
fn newTab(self: *App) !void {
    const alloc = self.core_app.alloc;
    var config = try configpkg.Config.load(alloc);
    defer config.deinit();

    var surface = try alloc.create(Surface);
    errdefer alloc.destroy(surface);
    try surface.init(self, self.core_app, &config);
    errdefer surface.deinit();

    try self.surfaces.append(alloc, surface);
    errdefer _ = self.surfaces.pop();

    // Create TabViewItem and add to TabView.
    const tab_view = self.tab_view orelse return error.AppInitFailed;
    const tvi_inspectable = try self.activateXamlType("Microsoft.UI.Xaml.Controls.TabViewItem");
    const tvi = try tvi_inspectable.queryInterface(com.ITabViewItem);
    defer tvi.release();

    const initial_title = try winrt.hstring("Terminal");
    defer winrt.deleteHString(initial_title);
    const boxed_title = try self.boxString(initial_title);
    defer _ = boxed_title.release();
    try tvi.putHeader(@ptrCast(boxed_title));
    try tvi.putIsClosable(false);

    // Set tab content to the Surface's SwapChainPanel via IContentControl.
    const panel = surface.swap_chain_panel orelse return error.AppInitFailed;
    const content_control = try tvi_inspectable.queryInterface(com.IContentControl);
    defer content_control.release();
    try content_control.putContent(@ptrCast(panel));

    // Add to TabItems collection.
    const tab_items = try tab_view.getTabItems();
    try tab_items.append(@ptrCast(tvi_inspectable));

    // Store the IInspectable reference on the surface for later title updates.
    surface.tab_view_item_inspectable = tvi_inspectable;

    // Select the new tab.
    const size = try tab_items.getSize();
    try tab_view.putSelectedIndex(@intCast(size - 1));
    self.active_surface_idx = @intCast(size - 1);
}

/// Close the active tab and its surface.
fn closeActiveTab(self: *App) void {
    if (self.surfaces.items.len == 0) return;
    self.closeTab(self.active_surface_idx);
}

/// Close a specific tab by index.
pub fn closeTab(self: *App, idx: usize) void {
    if (idx >= self.surfaces.items.len) return;

    const surface = self.surfaces.items[idx];

    // Remove from TabView.
    if (self.tab_view) |tv| {
        const tab_items = tv.getTabItems() catch |err| {
            log.warn("closeTab: getTabItems failed: {}", .{err});
            return;
        };
        tab_items.removeAt(@intCast(idx)) catch |err| {
            log.warn("closeTab: removeAt({}) failed: {}", .{ idx, err });
        };
    }

    // Cleanup surface.
    surface.deinit();
    self.core_app.alloc.destroy(surface);
    _ = self.surfaces.orderedRemove(idx);

    // Adjust active index or quit if no tabs remain.
    if (self.surfaces.items.len == 0) {
        self.running = false;
        if (self.xaml_app) |xa| {
            xa.exit() catch {};
        }
    } else if (self.active_surface_idx >= self.surfaces.items.len) {
        self.active_surface_idx = self.surfaces.items.len - 1;
    }
}

/// Close a surface by pointer (called from Surface.close).
pub fn closeSurface(self: *App, surface: *Surface) void {
    for (self.surfaces.items, 0..) |s, i| {
        if (s == surface) {
            self.closeTab(i);
            return;
        }
    }
    // Fallback: close the app if surface not found
    if (self.hwnd) |hwnd| {
        _ = os.PostMessageW(hwnd, os.WM_CLOSE, 0, 0);
    }
}

/// Get the currently active Surface, or null if none.
pub fn activeSurface(self: *App) ?*Surface {
    if (self.surfaces.items.len == 0) return null;
    if (self.active_surface_idx >= self.surfaces.items.len) return null;
    return self.surfaces.items[self.active_surface_idx];
}

// ---------------------------------------------------------------
// TabView event callbacks
// ---------------------------------------------------------------

fn onTabCloseRequested(self: *App, _: *anyopaque, _: *anyopaque) void {
    log.info("onTabCloseRequested", .{});
    self.closeActiveTab();
}

fn onAddTabButtonClick(self: *App, _: *anyopaque, _: *anyopaque) void {
    log.info("onAddTabButtonClick", .{});
    self.newTab() catch |err| {
        log.err("Failed to create new tab: {}", .{err});
    };
}

fn onSelectionChanged(self: *App, _: *anyopaque, _: *anyopaque) void {
    log.info("onSelectionChanged", .{});
    if (self.tab_view) |tv| {
        const idx = tv.getSelectedIndex() catch return;
        if (idx >= 0 and @as(usize, @intCast(idx)) < self.surfaces.items.len) {
            const new_idx: usize = @intCast(idx);
            // Notify old surface it lost focus.
            if (new_idx != self.active_surface_idx) {
                if (self.active_surface_idx < self.surfaces.items.len) {
                    self.surfaces.items[self.active_surface_idx].core_surface.focusCallback(false) catch {};
                }
            }
            self.active_surface_idx = new_idx;
            // Notify new surface it gained focus.
            self.surfaces.items[new_idx].core_surface.focusCallback(true) catch {};
        }
    }
}

// ---------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------

/// Activate a XAML type by name. Tries XAML type system first (via IXamlMetadataProvider),
/// falls back to RoActivateInstance for built-in types.
fn activateXamlType(self: *App, comptime class_name: [:0]const u8) !*winrt.IInspectable {
    // Try XAML type system first (required for WinUI3 custom controls like TabView).
    if (self.app_outer.provider) |provider| {
        const name = try winrt.hstring(class_name);
        defer winrt.deleteHString(name);
        if (provider.getXamlType(name)) |xaml_type| {
            defer xaml_type.release();
            return xaml_type.activateInstance();
        } else |_| {}
    }
    // Fallback to RoActivateInstance (works for base framework types).
    const name = try winrt.hstring(class_name);
    defer winrt.deleteHString(name);
    return winrt.activateInstance(name);
}

/// Box an HSTRING as an IInspectable via Windows.Foundation.PropertyValue.CreateString.
fn boxString(_: *App, str: winrt.HSTRING) !*winrt.IInspectable {
    log.info("boxString: getActivationFactory(IPropertyValueStatics)...", .{});
    const class_name = try winrt.hstring("Windows.Foundation.PropertyValue");
    defer winrt.deleteHString(class_name);
    const factory = try winrt.getActivationFactory(com.IPropertyValueStatics, class_name);
    defer factory.release();
    log.info("boxString: createString...", .{});
    const result = try factory.createString(str);
    log.info("boxString: OK", .{});
    return result;
}

/// Toggle fullscreen mode using Win32 borderless window approach.
fn toggleFullscreen(self: *App) void {
    const hwnd = self.hwnd orelse return;

    if (self.is_fullscreen) {
        // Restore windowed mode.
        _ = os.SetWindowLongPtrW(hwnd, os.GWL_STYLE, self.saved_style);
        _ = os.SetWindowPlacement(hwnd, &self.saved_placement);
        const SWP_NOMOVE = 0x0002;
        const SWP_NOSIZE = 0x0001;
        _ = os.SetWindowPos(hwnd, null, 0, 0, 0, 0, os.SWP_FRAMECHANGED | os.SWP_NOOWNERZORDER | os.SWP_NOZORDER | SWP_NOMOVE | SWP_NOSIZE);
        self.is_fullscreen = false;
    } else {
        // Save current state and enter fullscreen.
        self.saved_style = os.GetWindowLongPtrW(hwnd, os.GWL_STYLE);
        _ = os.GetWindowPlacement(hwnd, &self.saved_placement);

        // Remove caption and thick frame for borderless.
        const new_style = self.saved_style & ~@as(usize, os.WS_OVERLAPPEDWINDOW);
        _ = os.SetWindowLongPtrW(hwnd, os.GWL_STYLE, new_style);

        // Expand to cover the full monitor.
        const monitor = os.MonitorFromWindow(hwnd, os.MONITOR_DEFAULTTONEAREST) orelse return;
        var mi: os.MONITORINFO = .{};
        if (os.GetMonitorInfoW(monitor, &mi) != 0) {
            _ = os.SetWindowPos(
                hwnd,
                os.HWND_TOP,
                mi.rcMonitor.left,
                mi.rcMonitor.top,
                mi.rcMonitor.right - mi.rcMonitor.left,
                mi.rcMonitor.bottom - mi.rcMonitor.top,
                os.SWP_FRAMECHANGED | os.SWP_NOOWNERZORDER,
            );
        }
        self.is_fullscreen = true;
    }
}

/// Load XamlControlsResources into Application.Resources.
/// This enables WinUI 3 custom controls (TabView, NavigationView, etc.)
/// to find their XAML templates. Without it, RoActivateInstance returns E_NOTIMPL.
fn loadXamlResources(xa: *com.IApplication) void {
    // The Application created via IApplicationFactory may not have Resources set.
    // get_Resources returns E_UNEXPECTED in that case. So we:
    // 1. Create a new ResourceDictionary
    // 2. Set it as Application.Resources via put_Resources
    // 3. Create XamlControlsResources
    // 4. Append XamlControlsResources to the ResourceDictionary's MergedDictionaries
    // This matches the C++/WinRT pattern: Resources().MergedDictionaries().Append(XamlControlsResources())

    log.info("loadXamlResources: starting...", .{});

    // Step 1: Create a ResourceDictionary.
    const rd_class = winrt.hstring("Microsoft.UI.Xaml.ResourceDictionary") catch {
        log.err("loadXamlResources: Failed to create ResourceDictionary HSTRING", .{});
        return;
    };
    defer winrt.deleteHString(rd_class);
    const rd_inspectable = winrt.activateInstance(rd_class) catch |err| {
        log.err("loadXamlResources step 1: ResourceDictionary creation failed: {}", .{err});
        return;
    };
    log.info("loadXamlResources step 1 OK: ResourceDictionary created", .{});

    // Step 2: Set it as Application.Resources.
    xa.putResources(@ptrCast(rd_inspectable)) catch |err| {
        log.err("loadXamlResources step 2: Application.put_Resources failed: {}", .{err});
        return;
    };
    log.info("loadXamlResources step 2 OK: ResourceDictionary set on Application", .{});

    // Step 3: QI for IResourceDictionary to get MergedDictionaries.
    const res_dict = rd_inspectable.queryInterface(com.IResourceDictionary) catch |err| {
        log.err("loadXamlResources step 3a: ResourceDictionary QI failed: {}", .{err});
        return;
    };
    defer res_dict.release();

    const merged = res_dict.getMergedDictionaries() catch |err| {
        log.err("loadXamlResources step 3b: get_MergedDictionaries failed: {}", .{err});
        return;
    };
    log.info("loadXamlResources step 3 OK: got MergedDictionaries", .{});

    // Step 4: Create XamlControlsResources and append to MergedDictionaries.
    const xcr_class = winrt.hstring("Microsoft.UI.Xaml.Controls.XamlControlsResources") catch {
        log.err("loadXamlResources step 4: Failed to create XamlControlsResources HSTRING", .{});
        return;
    };
    defer winrt.deleteHString(xcr_class);
    const xcr = winrt.activateInstance(xcr_class) catch |err| {
        log.err("loadXamlResources step 4: XamlControlsResources creation failed: {}", .{err});
        return;
    };
    log.info("loadXamlResources step 4a OK: XamlControlsResources created", .{});

    merged.append(@ptrCast(xcr)) catch |err| {
        log.err("loadXamlResources step 4b: MergedDictionaries.Append failed: {}", .{err});
        return;
    };
    log.info("loadXamlResources OK: XamlControlsResources loaded via MergedDictionaries", .{});
}

fn drainMailbox(self: *App) void {
    log.info("drainMailbox: tick...", .{});
    self.core_app.tick(self) catch |err| {
        log.warn("tick error: {}", .{err});
    };
    log.info("drainMailbox: tick done", .{});
}

fn setTitle(self: *App, title: [:0]const u8) void {
    log.info("setTitle: \"{s}\"", .{title});
    const h = winrt.hstringRuntime(self.core_app.alloc, title) catch |err| {
        log.warn("setTitle: hstringRuntime failed: {}", .{err});
        return;
    };
    defer winrt.deleteHString(h);

    // Update window title bar.
    if (self.window) |window| {
        log.info("setTitle: putTitle...", .{});
        window.putTitle(h) catch {};
        log.info("setTitle: putTitle done", .{});
    }

    // Update active tab header.
    if (self.activeSurface()) |surface| {
        if (surface.tab_view_item_inspectable) |tvi_insp| {
            log.info("setTitle: QI for ITabViewItem...", .{});
            const tvi = tvi_insp.queryInterface(com.ITabViewItem) catch |err| {
                log.warn("setTitle: QI ITabViewItem failed: {}", .{err});
                return;
            };
            defer tvi.release();
            // Box the string as IInspectable for the Header property.
            log.info("setTitle: boxString...", .{});
            const boxed = self.boxString(h) catch |err| {
                log.warn("setTitle: boxString failed: {}", .{err});
                return;
            };
            defer _ = boxed.release();
            log.info("setTitle: putHeader...", .{});
            tvi.putHeader(@ptrCast(boxed)) catch {};
            log.info("setTitle: putHeader done", .{});
        }
    }
    log.info("setTitle: completed", .{});
}

// ---------------------------------------------------------------
// HWND subclass procedure and per-message handlers
// ---------------------------------------------------------------

/// Win32 subclass procedure callback.
/// Installed via SetWindowSubclass on the WinUI 3 window's HWND to intercept
/// input messages before WinUI 3's own window procedure processes them.
fn subclassProc(
    hwnd: os.HWND,
    msg: os.UINT,
    wparam: os.WPARAM,
    lparam: os.LPARAM,
    _: usize,
    ref_data: usize,
) callconv(.winapi) os.LRESULT {
    const app: *App = @ptrFromInt(ref_data);

    switch (msg) {
        os.WM_CLOSE => {
            // Let WinUI3 handle WM_CLOSE normally — the Closed event handler
            // (onWindowClosed) will do cleanup and call Application.Exit().
            app.running = false;
            if (app.xaml_app) |xa| xa.exit() catch {};
            return os.DefSubclassProc(hwnd, msg, wparam, lparam);
        },
        os.WM_SYSCOMMAND => {
            const wp: usize = @bitCast(wparam);
            if ((wp & 0xFFF0) == os.SC_CLOSE) {
                app.running = false;
                if (app.xaml_app) |xa| xa.exit() catch {};
                return os.DefSubclassProc(hwnd, msg, wparam, lparam);
            }
        },
        os.WM_ENTERSIZEMOVE => return handleEnterSizeMove(app, hwnd),
        os.WM_EXITSIZEMOVE => return handleExitSizeMove(app, hwnd),
        os.WM_TIMER => return handleTimer(app, hwnd, msg, wparam, lparam),
        os.WM_SIZE => return handleSize(app, hwnd, msg, wparam, lparam),
        os.WM_PAINT => return handlePaint(hwnd, msg, wparam, lparam),
        os.WM_ERASEBKGND => return 1,
        os.WM_KEYDOWN, os.WM_SYSKEYDOWN => return handleKeyInput(app, hwnd, msg, wparam, lparam, true),
        os.WM_KEYUP, os.WM_SYSKEYUP => return handleKeyInput(app, hwnd, msg, wparam, lparam, false),
        os.WM_CHAR => return handleChar(app, hwnd, msg, wparam, lparam),
        os.WM_MOUSEMOVE => return handleMouseMove(app, hwnd, msg, wparam, lparam),
        os.WM_LBUTTONDOWN => return handleMouseButton(app, hwnd, msg, wparam, lparam, .left, .press),
        os.WM_RBUTTONDOWN => return handleMouseButton(app, hwnd, msg, wparam, lparam, .right, .press),
        os.WM_MBUTTONDOWN => return handleMouseButton(app, hwnd, msg, wparam, lparam, .middle, .press),
        os.WM_LBUTTONUP => return handleMouseButton(app, hwnd, msg, wparam, lparam, .left, .release),
        os.WM_RBUTTONUP => return handleMouseButton(app, hwnd, msg, wparam, lparam, .right, .release),
        os.WM_MBUTTONUP => return handleMouseButton(app, hwnd, msg, wparam, lparam, .middle, .release),
        os.WM_MOUSEWHEEL => return handleScroll(app, hwnd, msg, wparam, lparam, .vertical),
        os.WM_MOUSEHWHEEL => return handleScroll(app, hwnd, msg, wparam, lparam, .horizontal),
        os.WM_DPICHANGED => return handleDpiChanged(app, hwnd, msg, wparam, lparam),
        os.WM_USER => return handleWakeup(app, hwnd, msg, wparam, lparam),
        os.WM_APP_BIND_SWAP_CHAIN => return handleBindSwapChain(app, wparam, lparam),
        // IME messages only handled in subclass as fallback (when input_hwnd failed).
        // When input_hwnd is active, IME messages go directly to inputWndProc.
        os.WM_IME_STARTCOMPOSITION => return ime.handleIMEStartComposition(app, hwnd, msg, wparam, lparam),
        os.WM_IME_COMPOSITION => return ime.handleIMEComposition(app, hwnd, msg, wparam, lparam),
        os.WM_IME_ENDCOMPOSITION => return ime.handleIMEEndComposition(app, hwnd, msg, wparam, lparam),
        os.WM_SETFOCUS => {
            // When the main or child HWND receives focus, redirect to our input HWND
            // so that keyboard/IME messages go to inputWndProc instead of WinUI3's TSF.
            if (app.input_hwnd) |input_hwnd| {
                if (hwnd != input_hwnd) {
                    log.info("subclassProc: WM_SETFOCUS on HWND=0x{x}, redirecting to input HWND=0x{x}", .{ @intFromPtr(hwnd), @intFromPtr(input_hwnd) });
                    _ = os.SetFocus(input_hwnd);
                    return 0;
                }
            }
        },
        else => {},
    }

    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

// --- Individual message handlers ---

fn handleEnterSizeMove(app: *App, hwnd: os.HWND) os.LRESULT {
    app.resizing = true;
    _ = os.SetTimer(hwnd, RESIZE_TIMER_ID, 16, null);
    return 0;
}

fn handleExitSizeMove(app: *App, hwnd: os.HWND) os.LRESULT {
    _ = os.KillTimer(hwnd, RESIZE_TIMER_ID);
    app.resizing = false;
    if (app.pending_size) |sz| {
        if (app.activeSurface()) |surface| surface.updateSize(sz.width, sz.height);
        app.pending_size = null;
    }
    return 0;
}

fn handleTimer(app: *App, hwnd: os.HWND, msg: os.UINT, wparam: os.WPARAM, lparam: os.LPARAM) os.LRESULT {
    if (app.pending_size) |sz| {
        if (app.activeSurface()) |surface| surface.updateSize(sz.width, sz.height);
        app.pending_size = null;
    }
    app.drainMailbox();
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

fn handleSize(app: *App, hwnd: os.HWND, msg: os.UINT, wparam: os.WPARAM, lparam: os.LPARAM) os.LRESULT {
    const lp: usize = @bitCast(lparam);
    const width: u32 = @intCast(lp & 0xFFFF);
    const height: u32 = @intCast((lp >> 16) & 0xFFFF);
    if (app.resizing) {
        app.pending_size = .{ .width = width, .height = height };
    } else {
        if (app.activeSurface()) |surface| surface.updateSize(width, height);
    }
    // Resize the input overlay HWND to match.
    if (app.input_hwnd) |input_hwnd| {
        _ = os.MoveWindow(input_hwnd, 0, 0, @intCast(width), @intCast(height), 0);
    }
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

fn handlePaint(hwnd: os.HWND, msg: os.UINT, wparam: os.WPARAM, lparam: os.LPARAM) os.LRESULT {
    // Let WinUI 3 handle painting entirely via DefSubclassProc.
    // Do NOT call BeginPaint/EndPaint here — that would validate the
    // paint region and prevent WinUI 3's own rendering from running.
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

fn handleKeyInput(app: *App, hwnd: os.HWND, msg: os.UINT, wparam: os.WPARAM, lparam: os.LPARAM, pressed: bool) os.LRESULT {
    if (app.activeSurface()) |surface| {
        const wp: usize = @bitCast(wparam);
        surface.handleKeyEvent(@truncate(wp), pressed);
    }
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

fn handleChar(app: *App, hwnd: os.HWND, msg: os.UINT, wparam: os.WPARAM, lparam: os.LPARAM) os.LRESULT {
    if (app.activeSurface()) |surface| {
        const wp: usize = @bitCast(wparam);
        surface.handleCharEvent(@truncate(wp));
    }
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

fn handleMouseMove(app: *App, hwnd: os.HWND, msg: os.UINT, wparam: os.WPARAM, lparam: os.LPARAM) os.LRESULT {
    if (app.activeSurface()) |surface| {
        const lp: usize = @bitCast(lparam);
        const x: i16 = @bitCast(@as(u16, @truncate(lp)));
        const y: i16 = @bitCast(@as(u16, @truncate(lp >> 16)));
        surface.handleMouseMove(@floatFromInt(x), @floatFromInt(y));
    }
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

fn handleMouseButton(
    app: *App,
    hwnd: os.HWND,
    msg: os.UINT,
    wparam: os.WPARAM,
    lparam: os.LPARAM,
    button: input.MouseButton,
    action: input.MouseButtonState,
) os.LRESULT {
    if (app.activeSurface()) |surface| {
        surface.handleMouseButton(button, action);
    }
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

const ScrollDirection = enum { vertical, horizontal };

fn handleScroll(
    app: *App,
    hwnd: os.HWND,
    msg: os.UINT,
    wparam: os.WPARAM,
    lparam: os.LPARAM,
    direction: ScrollDirection,
) os.LRESULT {
    if (app.activeSurface()) |surface| {
        const wp: usize = @bitCast(wparam);
        const delta: i16 = @bitCast(@as(u16, @truncate(wp >> 16)));
        const offset = @as(f64, @floatFromInt(delta)) / 120.0;
        switch (direction) {
            .vertical => surface.handleScroll(0, offset),
            .horizontal => surface.handleScroll(offset, 0),
        }
    }
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

fn handleDpiChanged(app: *App, hwnd: os.HWND, msg: os.UINT, wparam: os.WPARAM, lparam: os.LPARAM) os.LRESULT {
    if (app.activeSurface()) |surface| surface.updateContentScale();
    // lparam points to the recommended new window rect from Windows.
    // Apply it so the window scales correctly on DPI change.
    const rect_ptr: ?*const os.RECT = @ptrFromInt(@as(usize, @bitCast(lparam)));
    if (rect_ptr) |rect| {
        _ = os.SetWindowPos(
            hwnd,
            null,
            rect.left,
            rect.top,
            rect.right - rect.left,
            rect.bottom - rect.top,
            os.SWP_NOZORDER | os.SWP_NOACTIVATE,
        );
    }
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

fn handleWakeup(app: *App, hwnd: os.HWND, msg: os.UINT, wparam: os.WPARAM, lparam: os.LPARAM) os.LRESULT {
    log.info("handleWakeup: drainMailbox...", .{});
    app.drainMailbox();
    log.info("handleWakeup: drainMailbox done", .{});
    return os.DefSubclassProc(hwnd, msg, wparam, lparam);
}

/// Handle WM_APP_BIND_SWAP_CHAIN: complete swap chain binding on the UI thread.
/// wparam carries the swap chain pointer, lparam carries the Surface pointer.
fn handleBindSwapChain(app: *App, wparam: os.WPARAM, lparam: os.LPARAM) os.LRESULT {
    const surface: *Surface = @ptrFromInt(@as(usize, @bitCast(lparam)));
    const swap_chain: *anyopaque = @ptrFromInt(@as(usize, @bitCast(wparam)));

    // Drop stale bind requests that arrive after a surface was removed.
    var alive = false;
    for (app.surfaces.items) |s| {
        if (s == surface) {
            alive = true;
            break;
        }
    }
    if (!alive) {
        log.warn("handleBindSwapChain: drop stale surface ptr=0x{x}", .{@intFromPtr(surface)});
        return 0;
    }

    surface.completeBindSwapChain(swap_chain);
    return 0;
}

// ---------------------------------------------------------------
// Vectored Exception Handler — capture STATUS_STOWED_EXCEPTION details
// ---------------------------------------------------------------

fn writeRaw(msg: []const u8) void {
    const K32 = std.os.windows.kernel32;
    const handle = K32.GetStdHandle(@bitCast(@as(i32, -12))); // STD_ERROR_HANDLE
    if (handle != std.os.windows.INVALID_HANDLE_VALUE and handle != null) {
        _ = K32.WriteFile(handle.?, msg.ptr, @intCast(msg.len), null, null);
    }
}

fn stowedExceptionHandler(info: *os.EXCEPTION_POINTERS) callconv(.winapi) c_long {
    const record = info.ExceptionRecord orelse return os.EXCEPTION_CONTINUE_SEARCH;

    // Only intercept STATUS_STOWED_EXCEPTION (0xC000027B).
    if (record.ExceptionCode != os.STATUS_STOWED_EXCEPTION) return os.EXCEPTION_CONTINUE_SEARCH;

    // Use direct WriteFile to bypass Zig's log locking (may be held when crash occurs).
    writeRaw("=== STATUS_STOWED_EXCEPTION caught ===\n");

    log.err("=== STATUS_STOWED_EXCEPTION caught ===", .{});
    log.err("  ExceptionAddress: 0x{x}", .{@intFromPtr(record.ExceptionAddress)});
    log.err("  NumberParameters: {}", .{record.NumberParameters});

    // Dump raw exception parameters.
    const n = @min(record.NumberParameters, 15);
    for (0..n) |i| {
        log.err("  ExceptionInformation[{}]: 0x{x}", .{ i, record.ExceptionInformation[i] });
    }

    // Try to parse stowed exception entries.
    // Common layout: ExceptionInformation[0] = count, ExceptionInformation[1] = pointer to array of pointers.
    if (record.NumberParameters >= 2) {
        const count = record.ExceptionInformation[0];
        const array_ptr = record.ExceptionInformation[1];

        if (count > 0 and count < 100 and array_ptr != 0) {
            log.err("  Attempting to read {} stowed exception(s) from 0x{x}...", .{ count, array_ptr });
            const entries: [*]const usize = @ptrFromInt(array_ptr);
            for (0..count) |i| {
                const entry_ptr = entries[i];
                if (entry_ptr == 0) {
                    log.err("  [{}] null entry", .{i});
                    continue;
                }
                const entry: *const os.STOWED_EXCEPTION_INFORMATION_V2 = @ptrFromInt(entry_ptr);
                log.err("  [{}] size={} sig=0x{x} HRESULT=0x{x} form={}", .{
                    i,
                    entry.size,
                    entry.signature,
                    @as(u32, @bitCast(entry.result_code)),
                    entry.exception_form,
                });
            }
        }
    }

    // Also try: ExceptionInformation[0] = pointer to single STOWED_EXCEPTION_INFORMATION_V2.
    if (record.NumberParameters >= 1 and record.ExceptionInformation[0] != 0) {
        const maybe_entry: *const os.STOWED_EXCEPTION_INFORMATION_V2 = @ptrFromInt(record.ExceptionInformation[0]);
        // Check for "SE02" (0x32304553) or "SE01" (0x31304553) signature.
        if (maybe_entry.signature == 0x32304553 or maybe_entry.signature == 0x31304553) {
            log.err("  Direct stowed entry: HRESULT=0x{x} (sig=0x{x})", .{
                @as(u32, @bitCast(maybe_entry.result_code)),
                maybe_entry.signature,
            });
        }
    }

    log.err("=== End stowed exception dump ===", .{});

    return os.EXCEPTION_CONTINUE_SEARCH;
}





