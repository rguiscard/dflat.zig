const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const DialogBox = @import("DialogBox.zig");

pub fn BoxProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
//    const ct:?*df.CTLWINDOW = df.GetControl(wnd);
    if (win.GetControl()) |ct| {
        switch (msg) {
            df.SETFOCUS, df.PAINT => {
                return false;
            },
            df.LEFT_BUTTON, df.BUTTON_RELEASED => {
                return win.getParent().sendMessage(msg, p1, p2);
            },
            df.BORDER => {
                const rtn = root.zBaseWndProc(df.BOX, win, msg, p1, p2);
//                if (ct.*.itext) |txt| {
//                    df.writeline(wnd, txt, 1, 0, df.FALSE);
//                }
                if (DialogBox.getCtlWindowText(ct)) |txt| {
                    df.writeline(wnd, @constCast(txt.ptr), 1, 0, df.FALSE);
                }
                return rtn;
            },
            else => {
            }
        }
    }
    return root.zBaseWndProc(df.BOX, win, msg, p1, p2);
}
