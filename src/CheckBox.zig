const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;
const DialogBox = @import("DialogBox.zig");
const Dialogs = @import("Dialogs.zig");

const VOID = q.VOID;

pub fn CheckBoxProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    if (win.GetControl()) |ct| {
        switch (msg)    {
            df.SETFOCUS => {
                if (p1 == 0)
                    _ = q.SendMessage(null, df.HIDE_CURSOR, VOID, VOID);
                // fall off ?
                const rtn = root.BaseWndProc(k.CHECKBOX, win, msg, p1, p2);
                DialogBox.SetFocusCursor(win);
                return rtn;
            },
            df.MOVE => {
                const rtn = root.BaseWndProc(k.CHECKBOX, win, msg, p1, p2);
                DialogBox.SetFocusCursor(win);
                return rtn;
            },
            df.PAINT => {
                var cb = "[ ]";
                if (ct.*.setting > 0)
                    cb = "[X]";
                _ = win.sendMessage(df.CLEARTEXT, 0, 0);
                _ = win.sendTextMessage(df.ADDTEXT, @constCast(cb), 0);
                DialogBox.SetFocusCursor(win);
            },
            df.KEYBOARD => {
                if (p1 == ' ') {
                    // fall through
                    ct.*.setting ^= df.ON;
                    _ = win.sendMessage(df.PAINT, 0, 0);
                    return true;
                }
            },
            df.LEFT_BUTTON => {
                ct.*.setting ^= df.ON;
                _ = win.sendMessage(df.PAINT, 0, 0);
                return true;
            },
            else => {
            }
        }
    }
    return root.BaseWndProc(k.CHECKBOX, win, msg, p1, p2);
}


pub fn CheckBoxSetting(db:*Dialogs.DBOX, cmd:c) bool {
    const ct:?*Dialogs.CTLWINDOW = DialogBox.FindCommand(db, cmd, k.CHECKBOX);
    if (ct) |ctl| {
        if (ctl.win) |_| {
            return (ctl.*.setting == df.ON);
        } else {
            return (ctl.*.isetting == df.ON);
        }
    }
    return false;
//    return ct ? (ct->wnd ? (ct->setting==ON) : (ct->isetting==ON)) : FALSE;
}
