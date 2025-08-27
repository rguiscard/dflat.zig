const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

pub fn BoxProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    const wnd = win.win;
    const ct:?*df.CTLWINDOW = df.GetControl(wnd);
    if (ct) |ctl| {
        switch (msg) {
            df.SETFOCUS, df.PAINT => {
                return df.FALSE;
            },
            df.LEFT_BUTTON, df.BUTTON_RELEASED => {
                return df.SendMessage(Window.GetParent(wnd), msg, p1, p2);
            },
            df.BORDER => {
                const rtn = root.zBaseWndProc(df.BOX, win, msg, p1, p2);
                if (ctl.*.itext) |txt| {
                    df.writeline(wnd, txt, 1, 0, df.FALSE);
                }
                return rtn;
            },
            else => {
            }
        }
    }
    return root.zBaseWndProc(df.BOX, win, msg, p1, p2);
}
