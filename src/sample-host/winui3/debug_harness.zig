const std = @import("std");

pub const RuntimeDebugConfig = struct {
    enable_tabview: bool = true,
    enable_xaml_resources: bool = true,
    tabview_empty: bool = false,
    tabview_item_no_content: bool = false,
    enable_tabview_handlers: bool = true,
    /// Individual handler control (only used when enable_tabview_handlers=true)
    enable_handler_close: bool = true,
    enable_handler_addtab: bool = true,
    enable_handler_selection: bool = true,
    tabview_append_item: bool = true,
    tabview_select_first: bool = true,

    pub fn load() RuntimeDebugConfig {
        return .{
            .enable_tabview = envBool("GHOSTTY_WINUI3_ENABLE_TABVIEW", true),
            .enable_xaml_resources = envBool("GHOSTTY_WINUI3_ENABLE_XAML_RESOURCES", true),
            .tabview_empty = envBool("GHOSTTY_WINUI3_TABVIEW_EMPTY", false),
            .tabview_item_no_content = envBool("GHOSTTY_WINUI3_TABVIEW_ITEM_NO_CONTENT", false),
            .enable_tabview_handlers = envBool("GHOSTTY_WINUI3_ENABLE_TABVIEW_HANDLERS", true),
            .enable_handler_close = envBool("GHOSTTY_WINUI3_HANDLER_CLOSE", true),
            .enable_handler_addtab = envBool("GHOSTTY_WINUI3_HANDLER_ADDTAB", true),
            .enable_handler_selection = envBool("GHOSTTY_WINUI3_HANDLER_SELECTION", true),
            .tabview_append_item = envBool("GHOSTTY_WINUI3_TABVIEW_APPEND_ITEM", true),
            .tabview_select_first = envBool("GHOSTTY_WINUI3_TABVIEW_SELECT_FIRST", true),
        };
    }

    pub fn log(self: RuntimeDebugConfig, logger: anytype) void {
        logger.info(
            "winui3 debug config: tabview={} xaml_resources={} tabview_empty={} item_no_content={} handlers={} close={} addtab={} selection={} append={} select={}",
            .{
                self.enable_tabview,
                self.enable_xaml_resources,
                self.tabview_empty,
                self.tabview_item_no_content,
                self.enable_tabview_handlers,
                self.enable_handler_close,
                self.enable_handler_addtab,
                self.enable_handler_selection,
                self.tabview_append_item,
                self.tabview_select_first,
            },
        );
    }
};

fn envBool(name: [:0]const u8, default_value: bool) bool {
    const val = std.process.getEnvVarOwned(std.heap.page_allocator, name) catch return default_value;
    defer std.heap.page_allocator.free(val);

    if (std.ascii.eqlIgnoreCase(val, "1") or
        std.ascii.eqlIgnoreCase(val, "true") or
        std.ascii.eqlIgnoreCase(val, "yes") or
        std.ascii.eqlIgnoreCase(val, "on"))
    {
        return true;
    }
    if (std.ascii.eqlIgnoreCase(val, "0") or
        std.ascii.eqlIgnoreCase(val, "false") or
        std.ascii.eqlIgnoreCase(val, "no") or
        std.ascii.eqlIgnoreCase(val, "off"))
    {
        return false;
    }
    return default_value;
}
