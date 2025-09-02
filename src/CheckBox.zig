const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

pub fn CheckBoxProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    const ct:?*df.CTLWINDOW = df.GetControl(wnd);
    if (ct) |ctl| {
        switch (msg)    {
            df.SETFOCUS => {
                if (p1 == 0)
                    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
                // fall off ?
                const rtn = root.zBaseWndProc(df.CHECKBOX, win, msg, p1, p2);
                df.SetFocusCursor(wnd);
                return rtn;
            },
            df.MOVE => {
                const rtn = root.zBaseWndProc(df.CHECKBOX, win, msg, p1, p2);
                df.SetFocusCursor(wnd);
                return rtn;
            },
            df.PAINT => {
                var cb = "[ ]";
                if (ctl.*.setting > 0)
                    cb = "[X]";
                _ = win.sendMessage(df.CLEARTEXT, 0, 0);
                _ = win.sendTextMessage(df.ADDTEXT, @constCast(cb), 0);
                _ = df.SetFocusCursor(wnd);
            },
            df.KEYBOARD => {
                if (p1 == ' ') {
                    // fall through
                    ctl.*.setting ^= df.ON;
                    _ = win.sendMessage(df.PAINT, 0, 0);
                    return true;
                }
            },
            df.LEFT_BUTTON => {
                ctl.*.setting ^= df.ON;
                _ = win.sendMessage(df.PAINT, 0, 0);
                return true;
            },
            else => {
            }
        }
    }
    return root.zBaseWndProc(df.CHECKBOX, win, msg, p1, p2);
}
