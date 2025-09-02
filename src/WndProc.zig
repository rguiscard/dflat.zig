const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");
const normal = @import("Normal.zig");
const helpbox = @import("HelpBox.zig");

// This is temporarily put all wndproc together.
// Once each file in c is ported to zig, this will not be in use.

// Here are the rules for window parameter
// # Coming from c
// - SendMessage(df.WINDOW)
// - BaseWndProc(df.WINDOW)
// - DefaultWndProc(df.WINDOW)
// - PostMessage (df.WINDOW)
// # Coming from zig
// - Window.sendMessage(*Window)
// - zBaseWndProc(*Window)
// - zDefaultWndProc(*Window)
// - EveneQueue(*Window)

pub export fn NormalProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) c_int {
    return if (normal.NormalProc(win, msg, p1, p2)) df.TRUE else df.FALSE;
}

pub fn ComboProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    _ = wnd;
    _ = msg;
    _ = p1;
    _ = p2;
    return false;
// not currently in use. port later.
//    return df.cComboProc(wnd, msg, p1, p2);
}

pub fn SpinButtonProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) bool {
    const wnd = win.win;
    _ = wnd;
    _ = msg;
    _ = p1;
    _ = p2;
    return false;
// not currently in use. port later.
//    return df.cSpinButtonProc(wnd, msg, p1, p2);
}

pub export fn InputBoxProc(win:*Window, msg:df.MESSAGE, p1:df.PARAM, p2:df.PARAM) c_int {
    const wnd = win.win;
    return df.cInputBoxProc(wnd, msg, p1, p2);
}
