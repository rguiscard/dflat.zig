const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const DialogBox = @import("DialogBox.zig");
const k = @import("Classes.zig").CLASS;
const q = @import("Message.zig");

pub fn BoxProc(win:*Window, msg: df.MESSAGE, params:q.Params) bool {
    const wnd = win.win;
    if (win.GetControl()) |ct| {
        switch (msg) {
            df.SETFOCUS, df.PAINT => {
                return false;
            },
            df.LEFT_BUTTON, df.BUTTON_RELEASED => {
                return win.getParent().sendMessage(msg, params);
            },
            df.BORDER => {
                const rtn = root.BaseWndProc(k.BOX, win, msg, params);
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
    return root.BaseWndProc(k.BOX, win, msg, params);
}
