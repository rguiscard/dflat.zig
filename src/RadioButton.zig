const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const DialogBox = @import("DialogBox.zig");

var rct = [_]?*df.CTLWINDOW{null}**df.MAXRADIOS;

var Setting:bool = true;

pub fn SetRadioButton(db:*df.DBOX, ct:*df.CTLWINDOW) void {
    Setting = false;
    PushRadioButton(db, @intCast(ct.*.command));
    Setting = true;
}

pub fn PushRadioButton(db:*df.DBOX, cmd:c_uint) void {
    const control = DialogBox.FindCommand(db, cmd, df.RADIOBUTTON);
    if (control) |ct| {
        // --- clear all the radio buttons
        //          in this group on the dialog box ---

        // -------- build a table of all radio buttons at the
        //      same x vector ----------
        for(&db.*.ctl) |*ctl| {
            if (ctl.*.Class == 0) // end of controls
                break;
            if (ctl.*.Class == df.RADIOBUTTON) {
                if (ct.*.dwnd.x == ctl.*.dwnd.x) {
                    const idx:usize = @intCast(ctl.*.dwnd.y);
                    rct[idx] = ctl;
                }
            }
        }
        // ----- find the start of the radiobutton group ----
        var i:usize = @intCast(ct.*.dwnd.y);

        while ((i >= 0) and (rct[i] != null)) {
            if (i == 0)
                break;
            i -|= 1;
        }

        // ---- ignore everthing before the group ------
        while (i >= 0) {
            rct[i] = null;
            if (i == 0)
                break;
            i -|= 1;
        }

        // ----- find the end of the radiobutton group ----
        i = @intCast(ct.*.dwnd.y);
        while (i < df.MAXRADIOS and rct[i] != null) {
            i += 1;
        }
        // ---- ignore everthing past the group ------
        while (i < df.MAXRADIOS) {
          rct[i] = null;
          i += 1;
        }

        for (0..df.MAXRADIOS) |idx| {
            if (rct[idx]) |ctl| {
                const wason = ctl.*.setting;
                ctl.*.setting = df.OFF;
                if (Setting) {
                    ctl.*.isetting = df.OFF;
                }
                if (wason > 0) {
                    const ctlwnd:df.WINDOW = @ptrCast(@alignCast(ctl.*.wnd));
                    _ = q.SendMessage(ctlwnd, df.PAINT, 0, 0);
                }
            }
        }
        // ----- set the specified radio button on -----
        ct.*.setting = df.ON;
        if (Setting)
            ct.*.isetting = df.ON;
        const ctwnd:df.WINDOW = @ptrCast(@alignCast(ct.*.wnd));
        _ = q.SendMessage(ctwnd, df.PAINT, 0, 0);
    }
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
                        SetRadioButton(db, ct);
                    }
                }
            },
            df.LEFT_BUTTON => {
                if (Window.GetParent(wnd).*.extension) |extension| {
                    const db:*df.DBOX = @alignCast(@ptrCast(extension));
                    SetRadioButton(db, ct);
                }
            },
            else => { 
            }
        }
    }
    return root.zBaseWndProc(df.RADIOBUTTON, win, msg, p1, p2);
}

pub fn RadioButtonSetting(db:*df.DBOX, cmd:c_uint) bool {
    const ctl = DialogBox.FindCommand(db, cmd, df.RADIOBUTTON);
    const rtn = if (ctl) |ct| (if (ct.*.wnd != null) (ct.*.setting==df.ON) else (ct.*.isetting==df.ON)) else false;
    return rtn;
//    return if (rtn) df.TRUE else df.FALSE;
}
