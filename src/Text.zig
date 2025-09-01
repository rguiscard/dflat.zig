const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

pub fn TextProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const wnd = win.win;
    switch (msg)    {
        df.SETFOCUS => {
            return df.TRUE;
        },
        df.LEFT_BUTTON => {
            return df.TRUE;
        },
        df.PAINT => {
            df.drawText(wnd);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.TEXT, win, msg, p1, p2);
}
