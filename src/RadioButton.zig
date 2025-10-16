const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
const DialogBox = @import("DialogBox.zig");
const Dialogs = @import("Dialogs.zig");

var rct = [_]?*Dialogs.CTLWINDOW{null}**Dialogs.MAXRADIOS;
var Setting:bool = true;

pub fn SetRadioButton(db:*Dialogs.DBOX, ct:*Dialogs.CTLWINDOW) void {
    Setting = false;
    PushRadioButton(db, ct.*.command);
    Setting = true;
}

pub fn PushRadioButton(db:*Dialogs.DBOX, cmd:c) void {
    const control = DialogBox.FindCommand(db, cmd, k.RADIOBUTTON);
    if (control) |ct| {
        // --- clear all the radio buttons
        //          in this group on the dialog box ---

        // -------- build a table of all radio buttons at the
        //      same x vector ----------
        for(&db.*.ctl) |*ctl| {
            if (ctl.*.Class == k.NORMAL) // end of controls
                break;
            if (ctl.*.Class == k.RADIOBUTTON) {
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
        while (i < Dialogs.MAXRADIOS and rct[i] != null) {
            i += 1;
        }
        // ---- ignore everthing past the group ------
        while (i < Dialogs.MAXRADIOS) {
          rct[i] = null;
          i += 1;
        }

        for (0..Dialogs.MAXRADIOS) |idx| {
            if (rct[idx]) |ctl| {
                const wason = ctl.*.setting;
                ctl.*.setting = df.OFF;
                if (Setting) {
                    ctl.*.isetting = df.OFF;
                }
                if (wason > 0) {
                    if (ctl.win) |cwin| {
                       _ = cwin.sendMessage(df.PAINT, .{.paint=.{null, false}});
                    }
                }
            }
        }
        // ----- set the specified radio button on -----
        ct.*.setting = df.ON;
        if (Setting)
            ct.*.isetting = df.ON;
        if (ct.win) |cwin| {
            _ = cwin.sendMessage(df.PAINT, .{.paint=.{null, false}});
        }
    }
}

pub fn RadioButtonProc(win: *Window, msg: df.MESSAGE, params:q.Params) bool {
    if (win.GetControl()) |ct| {
        switch (msg) {
            df.SETFOCUS => {
                if (params.yes == false)
                    _ = q.SendMessage(null, df.HIDE_CURSOR, q.none);
            },
            df.MOVE => {
                const rtn = root.BaseWndProc(k.RADIOBUTTON,win,msg,params);
                DialogBox.SetFocusCursor(win);
                return rtn;
            },
            df.PAINT => {
                var rb = "( )";
                if (ct.*.setting > 0)
                    rb = "(\x07)";
                _ = win.sendMessage(df.CLEARTEXT, .{.legacy=.{0, 0}});
                _ = win.sendTextMessage(df.ADDTEXT, @constCast(rb), 0);
                DialogBox.SetFocusCursor(win);
            },
            df.KEYBOARD => {
                const p1 = params.legacy[0];
                if (p1 == ' ') {
                    // fall through
                    if (win.parent) |pw| {
                        if (pw.extension) |extension| {
                            const db:*Dialogs.DBOX = extension.dbox;
                            SetRadioButton(db, ct);
                        }
                    }
                }
            },
            df.LEFT_BUTTON => {
                if (win.parent) |pw| {
                    if (pw.extension) |extension| {
                        const db:*Dialogs.DBOX = extension.dbox;
                        SetRadioButton(db, ct);
                    }
                }
            },
            else => { 
            }
        }
    }
    return root.BaseWndProc(k.RADIOBUTTON, win, msg, params);
}

pub fn RadioButtonSetting(db:*Dialogs.DBOX, cmd:c) bool {
    const ctl = DialogBox.FindCommand(db, cmd, k.RADIOBUTTON);
    const rtn = if (ctl) |ct| (if (ct.win != null) (ct.*.setting==df.ON) else (ct.*.isetting==df.ON)) else false;
    return rtn;
//    return if (rtn) df.TRUE else df.FALSE;
}
