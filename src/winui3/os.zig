/// Win32 API types, constants, structs, and extern declarations needed by the WinUI 3 apprt.
/// Expanded to support full terminal surface implementation (input, clipboard, IME, DPI, subclass).
const std = @import("std");
const win32 = std.os.windows;

// --- Primitive types ---
pub const HWND = win32.HANDLE;
pub const HDC = win32.HANDLE;
pub const HGLRC = win32.HANDLE;
pub const HINSTANCE = win32.HANDLE;
pub const HICON = win32.HANDLE;
pub const HCURSOR = win32.HANDLE;
pub const HBRUSH = win32.HANDLE;
pub const HMENU = win32.HANDLE;
pub const HANDLE = win32.HANDLE;
pub const LPARAM = win32.LPARAM;
pub const WPARAM = win32.WPARAM;
pub const LRESULT = win32.LRESULT;
pub const BOOL = win32.BOOL;
pub const UINT = c_uint;
pub const DWORD = win32.DWORD;
pub const LONG = c_long;
pub const WORD = u16;
pub const ATOM = u16;
pub const BYTE = u8;
pub const LPVOID = ?*anyopaque;
pub const LPCWSTR = [*:0]const u16;

// --- Window messages ---
pub const WM_CREATE: UINT = 0x0001;
pub const WM_DESTROY: UINT = 0x0002;
pub const WM_SIZE: UINT = 0x0005;
pub const WM_PAINT: UINT = 0x000F;
pub const WM_CLOSE: UINT = 0x0010;
pub const WM_QUIT: UINT = 0x0012;
pub const WM_SYSCOMMAND: UINT = 0x0112;
pub const WM_ERASEBKGND: UINT = 0x0014;
pub const WM_KEYDOWN: UINT = 0x0100;
pub const WM_KEYUP: UINT = 0x0101;
pub const WM_CHAR: UINT = 0x0102;
pub const WM_SYSKEYDOWN: UINT = 0x0104;
pub const WM_SYSKEYUP: UINT = 0x0105;
pub const WM_TIMER: UINT = 0x0113;
pub const WM_MOUSEMOVE: UINT = 0x0200;
pub const WM_LBUTTONDOWN: UINT = 0x0201;
pub const WM_LBUTTONUP: UINT = 0x0202;
pub const WM_RBUTTONDOWN: UINT = 0x0204;
pub const WM_RBUTTONUP: UINT = 0x0205;
pub const WM_MBUTTONDOWN: UINT = 0x0207;
pub const WM_MBUTTONUP: UINT = 0x0208;
pub const WM_MOUSEWHEEL: UINT = 0x020A;
pub const WM_MOUSEHWHEEL: UINT = 0x020E;
pub const WM_ENTERSIZEMOVE: UINT = 0x0231;
pub const WM_EXITSIZEMOVE: UINT = 0x0232;
pub const WM_DPICHANGED: UINT = 0x02E0;
pub const WM_USER: UINT = 0x0400;

// --- Application-defined messages (WM_USER + N) ---
/// Posted by the renderer thread to request swap chain binding on the UI thread.
pub const WM_APP_BIND_SWAP_CHAIN: UINT = WM_USER + 1;

// --- Window styles ---
pub const WS_OVERLAPPEDWINDOW: DWORD = 0x00CF0000;
pub const WS_VISIBLE: DWORD = 0x10000000;
pub const CW_USEDEFAULT: c_int = @bitCast(@as(c_uint, 0x80000000));

// --- Class styles ---
pub const CS_OWNDC: UINT = 0x0020;
pub const CS_HREDRAW: UINT = 0x0002;
pub const CS_VREDRAW: UINT = 0x0001;

// --- Misc constants ---
pub const IDC_ARROW: LPCWSTR = @ptrFromInt(32512);
pub const COLOR_WINDOW: c_int = 5;
pub const SW_SHOW: c_int = 5;
pub const PM_REMOVE: UINT = 0x0001;
pub const PM_NOREMOVE: UINT = 0x0000;
pub const GWLP_USERDATA: c_int = -21;
pub const CF_UNICODETEXT: UINT = 13;
pub const GMEM_MOVEABLE: UINT = 0x0002;
pub const SC_CLOSE: usize = 0xF060;

// --- MsgWaitForMultipleObjectsEx ---
pub const QS_ALLINPUT: DWORD = 0x04FF;
pub const MWMO_INPUTAVAILABLE: DWORD = 0x0004;
pub const WAIT_TIMEOUT: DWORD = 0x00000102;
pub const INFINITE: DWORD = 0xFFFFFFFF;

// --- MapVirtualKeyW ---
pub const MAPVK_VK_TO_CHAR: UINT = 2;

// --- SetWindowPos flags ---
pub const SWP_NOZORDER: UINT = 0x0004;
pub const SWP_NOACTIVATE: UINT = 0x0010;

// --- Pixel format ---
pub const PFD_DRAW_TO_WINDOW: DWORD = 0x00000004;
pub const PFD_SUPPORT_OPENGL: DWORD = 0x00000020;
pub const PFD_DOUBLEBUFFER: DWORD = 0x00000001;
pub const PFD_TYPE_RGBA: BYTE = 0;
pub const PFD_MAIN_PLANE: BYTE = 0;

// --- Structs ---
pub const WNDCLASSEXW = extern struct {
    cbSize: UINT = @sizeOf(WNDCLASSEXW),
    style: UINT = 0,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(.winapi) LRESULT,
    cbClsExtra: c_int = 0,
    cbWndExtra: c_int = 0,
    hInstance: HINSTANCE,
    hIcon: ?HICON = null,
    hCursor: ?HCURSOR = null,
    hbrBackground: ?HBRUSH = null,
    lpszMenuName: ?LPCWSTR = null,
    lpszClassName: LPCWSTR,
    hIconSm: ?HICON = null,
};

pub const PIXELFORMATDESCRIPTOR = extern struct {
    nSize: WORD = @sizeOf(PIXELFORMATDESCRIPTOR),
    nVersion: WORD = 1,
    dwFlags: DWORD = 0,
    iPixelType: BYTE = 0,
    cColorBits: BYTE = 0,
    cRedBits: BYTE = 0,
    cRedShift: BYTE = 0,
    cGreenBits: BYTE = 0,
    cGreenShift: BYTE = 0,
    cBlueBits: BYTE = 0,
    cBlueShift: BYTE = 0,
    cAlphaBits: BYTE = 0,
    cAlphaShift: BYTE = 0,
    cAccumBits: BYTE = 0,
    cAccumRedBits: BYTE = 0,
    cAccumGreenBits: BYTE = 0,
    cAccumBlueBits: BYTE = 0,
    cAccumAlphaBits: BYTE = 0,
    cDepthBits: BYTE = 0,
    cStencilBits: BYTE = 0,
    cAuxBuffers: BYTE = 0,
    iLayerType: BYTE = 0,
    bReserved: BYTE = 0,
    dwLayerMask: DWORD = 0,
    dwVisibleMask: DWORD = 0,
    dwDamageMask: DWORD = 0,
};

pub const POINT = extern struct {
    x: LONG = 0,
    y: LONG = 0,
};

pub const MSG = extern struct {
    hwnd: ?HWND = null,
    message: UINT = 0,
    wParam: WPARAM = 0,
    lParam: LPARAM = 0,
    time: DWORD = 0,
    pt: POINT = .{},
};

pub const RECT = extern struct {
    left: LONG = 0,
    top: LONG = 0,
    right: LONG = 0,
    bottom: LONG = 0,
};

pub const PAINTSTRUCT = extern struct {
    hdc: ?HDC = null,
    fErase: BOOL = 0,
    rcPaint: RECT = .{},
    fRestore: BOOL = 0,
    fIncUpdate: BOOL = 0,
    rgbReserved: [32]BYTE = [_]BYTE{0} ** 32,
};

// --- Window subclass callback type ---
pub const SUBCLASSPROC = *const fn (HWND, UINT, WPARAM, LPARAM, usize, usize) callconv(.winapi) LRESULT;

// --- user32 extern declarations ---
pub extern "user32" fn RegisterClassExW(lpWndClass: *const WNDCLASSEXW) callconv(.winapi) ATOM;
pub extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: LPCWSTR,
    lpWindowName: LPCWSTR,
    dwStyle: DWORD,
    x: c_int,
    y: c_int,
    nWidth: c_int,
    nHeight: c_int,
    hWndParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: HINSTANCE,
    lpParam: LPVOID,
) callconv(.winapi) ?HWND;
pub extern "user32" fn DestroyWindow(hWnd: HWND) callconv(.winapi) BOOL;
pub extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: c_int) callconv(.winapi) BOOL;
pub extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.winapi) BOOL;
pub extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) BOOL;
pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
pub extern "user32" fn PostQuitMessage(nExitCode: c_int) callconv(.winapi) void;
pub extern "user32" fn PostMessageW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) BOOL;
pub extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub extern "user32" fn LoadCursorW(hInstance: ?HINSTANCE, lpCursorName: LPCWSTR) callconv(.winapi) ?HCURSOR;
pub extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;
pub extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) callconv(.winapi) ?HDC;
pub extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *const PAINTSTRUCT) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: c_int, dwNewLong: usize) callconv(.winapi) usize;
pub extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: c_int) callconv(.winapi) usize;
pub extern "user32" fn InvalidateRect(hWnd: HWND, lpRect: ?*const RECT, bErase: BOOL) callconv(.winapi) BOOL;
pub extern "user32" fn GetCursorPos(lpPoint: *POINT) callconv(.winapi) BOOL;
pub extern "user32" fn ScreenToClient(hWnd: HWND, lpPoint: *POINT) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowTextW(hWnd: HWND, lpString: LPCWSTR) callconv(.winapi) BOOL;
pub extern "user32" fn GetDpiForWindow(hWnd: HWND) callconv(.winapi) UINT;
pub extern "user32" fn GetKeyState(nVirtKey: c_int) callconv(.winapi) c_short;
pub extern "user32" fn OpenClipboard(hWndNewOwner: ?HWND) callconv(.winapi) BOOL;
pub extern "user32" fn CloseClipboard() callconv(.winapi) BOOL;
pub extern "user32" fn GetClipboardData(uFormat: UINT) callconv(.winapi) LPVOID;
pub extern "user32" fn SetClipboardData(uFormat: UINT, hMem: LPVOID) callconv(.winapi) LPVOID;
pub extern "user32" fn EmptyClipboard() callconv(.winapi) BOOL;
pub extern "user32" fn SetCapture(hWnd: HWND) callconv(.winapi) ?HWND;
pub extern "user32" fn ReleaseCapture() callconv(.winapi) BOOL;
pub extern "user32" fn GetFocus() callconv(.winapi) ?HWND;
pub extern "user32" fn GetWindow(hWnd: HWND, uCmd: UINT) callconv(.winapi) ?HWND;
pub extern "user32" fn GetAncestor(hWnd: HWND, gaFlags: UINT) callconv(.winapi) ?HWND;
pub const GW_CHILD: UINT = 5;
pub const GW_HWNDNEXT: UINT = 2;
pub const GA_ROOT: UINT = 2;
pub extern "user32" fn UnregisterClassW(lpClassName: LPCWSTR, hInstance: ?HINSTANCE) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowPos(
    hWnd: HWND,
    hWndInsertAfter: ?HWND,
    X: c_int,
    Y: c_int,
    cx: c_int,
    cy: c_int,
    uFlags: UINT,
) callconv(.winapi) BOOL;
pub extern "user32" fn SetTimer(hWnd: ?HWND, nIDEvent: usize, uElapse: UINT, lpTimerFunc: ?*const anyopaque) callconv(.winapi) usize;
pub extern "user32" fn KillTimer(hWnd: ?HWND, uIDEvent: usize) callconv(.winapi) BOOL;
pub extern "user32" fn MsgWaitForMultipleObjectsEx(
    nCount: DWORD,
    pHandles: ?[*]const HANDLE,
    dwMilliseconds: DWORD,
    dwWakeMask: DWORD,
    dwFlags: DWORD,
) callconv(.winapi) DWORD;

pub extern "user32" fn MapVirtualKeyW(uCode: UINT, uMapType: UINT) callconv(.winapi) UINT;
pub extern "user32" fn GetKeyboardLayout(idThread: DWORD) callconv(.winapi) usize;

// --- kernel32 extern declarations ---
pub extern "kernel32" fn GetModuleHandleW(lpModuleName: ?LPCWSTR) callconv(.winapi) ?HINSTANCE;
pub extern "kernel32" fn GlobalAlloc(uFlags: UINT, dwBytes: usize) callconv(.winapi) LPVOID;
pub extern "kernel32" fn GlobalLock(hMem: LPVOID) callconv(.winapi) LPVOID;
pub extern "kernel32" fn GlobalUnlock(hMem: LPVOID) callconv(.winapi) BOOL;
pub extern "kernel32" fn GlobalFree(hMem: LPVOID) callconv(.winapi) LPVOID;

// --- gdi32 extern declarations ---
pub extern "gdi32" fn ChoosePixelFormat(hdc: HDC, ppfd: *const PIXELFORMATDESCRIPTOR) callconv(.winapi) c_int;
pub extern "gdi32" fn SetPixelFormat(hdc: HDC, format: c_int, ppfd: *const PIXELFORMATDESCRIPTOR) callconv(.winapi) BOOL;
pub extern "gdi32" fn SwapBuffers(hdc: HDC) callconv(.winapi) BOOL;

// GetDC/ReleaseDC are exported from user32.dll (not gdi32)
pub extern "user32" fn GetDC(hWnd: ?HWND) callconv(.winapi) ?HDC;
pub extern "user32" fn ReleaseDC(hWnd: ?HWND, hDC: HDC) callconv(.winapi) c_int;

// --- opengl32 extern declarations ---
pub extern "opengl32" fn wglCreateContext(hdc: HDC) callconv(.winapi) ?HGLRC;
pub extern "opengl32" fn wglMakeCurrent(hdc: ?HDC, hglrc: ?HGLRC) callconv(.winapi) BOOL;
pub extern "opengl32" fn wglDeleteContext(hglrc: HGLRC) callconv(.winapi) BOOL;
pub extern "opengl32" fn wglGetProcAddress(lpszProc: [*:0]const u8) callconv(.winapi) ?*const anyopaque;

// --- comctl32 extern declarations (window subclass API) ---
pub extern "comctl32" fn SetWindowSubclass(hWnd: HWND, pfnSubclass: SUBCLASSPROC, uIdSubclass: usize, dwRefData: usize) callconv(.winapi) BOOL;
pub extern "comctl32" fn DefSubclassProc(hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub extern "comctl32" fn RemoveWindowSubclass(hWnd: HWND, pfnSubclass: SUBCLASSPROC, uIdSubclass: usize) callconv(.winapi) BOOL;

// --- IME types ---
pub const HIMC = ?*anyopaque;

// --- IME constants ---
pub const WM_IME_STARTCOMPOSITION: UINT = 0x010D;
pub const WM_IME_ENDCOMPOSITION: UINT = 0x010E;
pub const WM_IME_COMPOSITION: UINT = 0x010F;
pub const GCS_COMPSTR: DWORD = 0x0008;
pub const GCS_RESULTSTR: DWORD = 0x0800;
pub const CFS_POINT: DWORD = 0x0002;

pub const COMPOSITIONFORM = extern struct {
    dwStyle: DWORD = 0,
    ptCurrentPos: POINT = .{},
    rcArea: RECT = .{},
};

// --- imm32 extern declarations ---
pub extern "imm32" fn ImmGetContext(hWnd: HWND) callconv(.winapi) HIMC;
pub extern "imm32" fn ImmReleaseContext(hWnd: HWND, hIMC: HIMC) callconv(.winapi) BOOL;
pub extern "imm32" fn ImmGetCompositionStringW(hIMC: HIMC, dwIndex: DWORD, lpBuf: LPVOID, dwBufLen: DWORD) callconv(.winapi) LONG;
pub extern "imm32" fn ImmSetCompositionWindow(hIMC: HIMC, lpCompForm: *const COMPOSITIONFORM) callconv(.winapi) BOOL;
pub extern "imm32" fn ImmAssociateContextEx(hWnd: HWND, hIMC: HIMC, dwFlags: DWORD) callconv(.winapi) BOOL;
pub const IACE_DEFAULT: DWORD = 0x0010;

// --- Window styles (for input overlay HWND) ---
pub const WS_CHILD: DWORD = 0x40000000;
pub const WS_EX_TRANSPARENT: DWORD = 0x00000020;
pub const WS_EX_NOACTIVATE: DWORD = 0x08000000;

// --- SetFocus / SetParent ---
pub extern "user32" fn SetFocus(hWnd: ?HWND) callconv(.winapi) ?HWND;
pub extern "user32" fn SetParent(hWndChild: HWND, hWndNewParent: ?HWND) callconv(.winapi) ?HWND;
pub extern "user32" fn MoveWindow(hWnd: HWND, X: c_int, Y: c_int, nWidth: c_int, nHeight: c_int, bRepaint: BOOL) callconv(.winapi) BOOL;

// --- WM_SETFOCUS / WM_KILLFOCUS ---
pub const WM_SETFOCUS: UINT = 0x0007;
pub const WM_KILLFOCUS: UINT = 0x0008;

// --- WM_IME_SETCONTEXT ---
pub const WM_IME_SETCONTEXT: UINT = 0x0281;
pub const WM_IME_NOTIFY: UINT = 0x0282;

// --- ImmSetOpenStatus / ImmGetOpenStatus ---
pub extern "imm32" fn ImmSetOpenStatus(hIMC: HIMC, fOpen: BOOL) callconv(.winapi) BOOL;
pub extern "imm32" fn ImmGetOpenStatus(hIMC: HIMC) callconv(.winapi) BOOL;

// --- Fullscreen support ---
pub const GWL_STYLE: c_int = -16;
pub const WS_CAPTION: DWORD = 0x00C00000;
pub const WS_THICKFRAME: DWORD = 0x00040000;
pub const SWP_FRAMECHANGED: UINT = 0x0020;
pub const SWP_NOOWNERZORDER: UINT = 0x0200;
pub const MONITOR_DEFAULTTONEAREST: DWORD = 0x00000002;
pub const HWND_TOP: ?HWND = null;

pub const WINDOWPLACEMENT = extern struct {
    length: UINT = @sizeOf(WINDOWPLACEMENT),
    flags: UINT = 0,
    showCmd: UINT = 0,
    ptMinPosition: POINT = .{},
    ptMaxPosition: POINT = .{},
    rcNormalPosition: RECT = .{},
};

pub const MONITORINFO = extern struct {
    cbSize: DWORD = @sizeOf(MONITORINFO),
    rcMonitor: RECT = .{},
    rcWork: RECT = .{},
    dwFlags: DWORD = 0,
};

pub extern "user32" fn GetWindowPlacement(hWnd: HWND, lpwndpl: *WINDOWPLACEMENT) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowPlacement(hWnd: HWND, lpwndpl: *const WINDOWPLACEMENT) callconv(.winapi) BOOL;
pub extern "user32" fn MonitorFromWindow(hWnd: HWND, dwFlags: DWORD) callconv(.winapi) ?HANDLE;
pub extern "user32" fn GetMonitorInfoW(hMonitor: HANDLE, lpmi: *MONITORINFO) callconv(.winapi) BOOL;

// --- winmm extern declarations ---
pub extern "winmm" fn timeBeginPeriod(uPeriod: UINT) callconv(.winapi) UINT;
pub extern "winmm" fn timeEndPeriod(uPeriod: UINT) callconv(.winapi) UINT;

// --- Vectored Exception Handling ---
pub const EXCEPTION_RECORD = extern struct {
    ExceptionCode: DWORD,
    ExceptionFlags: DWORD,
    ExceptionRecord: ?*EXCEPTION_RECORD,
    ExceptionAddress: ?*anyopaque,
    NumberParameters: DWORD,
    ExceptionInformation: [15]usize,
};

pub const EXCEPTION_POINTERS = extern struct {
    ExceptionRecord: ?*EXCEPTION_RECORD,
    ContextRecord: ?*anyopaque,
};

pub const EXCEPTION_CONTINUE_SEARCH: c_long = 0;
pub const STATUS_STOWED_EXCEPTION: DWORD = 0xC000027B;

/// Stowed exception info v2 header — first 8 bytes of each entry.
pub const STOWED_EXCEPTION_INFORMATION_V2 = extern struct {
    size: u32,
    signature: u32, // "SE02" = 0x32304553, "SE01" = 0x31304553
    result_code: i32, // HRESULT
    exception_form: u32,
    // ... more fields follow but we only need result_code
};

pub const VectoredExceptionHandler = *const fn (*EXCEPTION_POINTERS) callconv(.winapi) c_long;
pub extern "kernel32" fn AddVectoredExceptionHandler(first: u32, handler: VectoredExceptionHandler) callconv(.winapi) ?*anyopaque;
pub extern "kernel32" fn RemoveVectoredExceptionHandler(handle: *anyopaque) callconv(.winapi) u32;

// --- Debug logging: redirect stderr to a file for GUI apps ---
pub extern "kernel32" fn SetStdHandle(nStdHandle: DWORD, hHandle: HANDLE) callconv(.winapi) BOOL;
pub const STD_ERROR_HANDLE: DWORD = @as(DWORD, @bitCast(@as(i32, -12)));

const CreateFileW = win32.kernel32.CreateFileW;
pub fn attachDebugConsole() void {
    // Redirect stderr to a log file next to the exe.
    const name = std.unicode.utf8ToUtf16LeStringLiteral("C:\\Users\\yuuji\\ghostty-win\\debug.log");
    const h = CreateFileW(
        name,
        win32.GENERIC_WRITE,
        win32.FILE_SHARE_READ,
        null,
        win32.CREATE_ALWAYS,
        0,
        null,
    );
    if (h != win32.INVALID_HANDLE_VALUE) {
        _ = SetStdHandle(STD_ERROR_HANDLE, h);
    }
}
