const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

pub fn RadioButtonProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    const wnd = win.win;
    const control = df.GetControl(wnd);
    if (control) |ct| {
        switch (msg) {
            df.SETFOCUS => {
                if (p1 == 0)
                    _ = q.SendMessage(null, df.HIDE_CURSOR, 0, 0);
            },
            df.MOVE => {
                const rtn = root.zBaseWndProc(df.RADIOBUTTON,win,msg,p1,p2);
                df.SetFocusCursor(wnd);
                return rtn;
            },
            df.PAINT => {
                var rb = "( )";
                if (ct.*.setting > 0)
                    rb = "(\x07)";
                _ = win.sendMessage(df.CLEARTEXT, 0, 0);
                _ = win.sendTextMessage(df.ADDTEXT, @constCast(rb), 0);
                _ = df.SetFocusCursor(wnd);
            },
            df.KEYBOARD => {
                if (p1 == ' ') {
                    // fall through
                    if (Window.GetParent(wnd).*.extension) |extension| {
                        const db:*df.DBOX = @alignCast(@ptrCast(extension));
                        df.SetRadioButton(db, ct);
                    }
                }
            },
            df.LEFT_BUTTON => {
                if (Window.GetParent(wnd).*.extension) |extension| {
                    const db:*df.DBOX = @alignCast(@ptrCast(extension));
                    df.SetRadioButton(db, ct);
                }
            },
            else => { 
            }
        }
    }
    return root.BaseWndProc(df.RADIOBUTTON, wnd, msg, p1, p2);
}
