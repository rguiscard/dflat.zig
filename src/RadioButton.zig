const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const DialogBox = @import("DialogBox.zig");

var Setting:bool = true;

pub export fn SetRadioButton(db:*df.DBOX, ct:*df.CTLWINDOW) callconv(.c) void {
    Setting = false;
    PushRadioButton(db, @intCast(ct.*.command));
    Setting = true;
}

pub export fn PushRadioButton(db:*df.DBOX, cmd:c_uint) void {
    const setting = if (Setting) df.TRUE else df.FALSE;
    df.cPushRadioButton(db, cmd, @intCast(setting));
}

pub fn RadioButtonProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
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
    return root.zBaseWndProc(df.RADIOBUTTON, win, msg, p1, p2);
}

pub export fn RadioButtonSetting(db:*df.DBOX, cmd:c_uint) callconv(.c) df.BOOL {
    const ctl = DialogBox.FindCommand(db, cmd, df.RADIOBUTTON);
    const rtn = if (ctl) |ct| (if (ct.*.wnd != null) (ct.*.setting==df.ON) else (ct.*.isetting==df.ON)) else false;
    return if (rtn) df.TRUE else df.FALSE;
}
