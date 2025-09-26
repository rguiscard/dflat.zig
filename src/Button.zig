const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const q = @import("Message.zig");
const k = @import("Classes.zig").CLASS;
const r = @import("Colors.zig");
const Window = @import("Window.zig");
const DialogBox = @import("DialogBox.zig");
const Dialogs = @import("Dialogs.zig");
const popdown = @import("PopDown.zig");
const textbox = @import("TextBox.zig");

fn PaintMsg(win: *Window, ct: *Dialogs.CTLWINDOW, rc: ?*df.RECT) void {
    const wnd = win.win;
    if (win.isVisible()) {
        if (win.TestAttribute(df.SHADOW) and (df.cfg.mono == 0)) {
            // -------- draw the button's shadow -------
            df.background = df.WndBackground(win.getParent().win);
            df.foreground = r.BLACK;
            for(1..@intCast(win.WindowWidth()+1)) |x| {
                df.wputch(wnd, 223, @intCast(x), 1);
            }
            df.wputch(wnd, 220, @intCast(win.WindowWidth()), 0);
        }
//        if (ct.itext) |itext| {
        if (DialogBox.getCtlWindowText(ct)) |itext| {
            if(root.global_allocator.allocSentinel(u8, itext.len+10, 0)) |txt| {
                defer root.global_allocator.free(txt);
                @memset(txt, 0);
                var start:usize = 0;
                if (ct.*.setting == df.OFF) {
                  txt[0] = df.CHANGECOLOR;
                  txt[1] = wnd.*.WindowColors[df.HILITE_COLOR][df.FG] | 0x80;
                  txt[2] = wnd.*.WindowColors[df.STD_COLOR][df.BG] | 0x80;
                  start = 3;
                }
                _ = popdown.CopyCommand(txt[start..],itext, (ct.*.setting == df.OFF), df.WndBackground(wnd));
                _ = win.sendMessage(df.CLEARTEXT, 0, 0);
                _ = win.sendTextMessage(df.ADDTEXT, @constCast(txt), 0);
            } else |_| {
            }
        }
        // --------- write the button's text -------
        textbox.WriteTextLine(win, rc, 0, win == Window.inFocus);
    }
}

fn LeftButtonMsg(win: *Window, msg: df.MESSAGE, ct: *Dialogs.CTLWINDOW) void {
    const wnd = win.win;
    if (df.cfg.mono == 0) {
        // --------- draw a pushed button --------
        df.background = df.WndBackground(win.getParent().win);
        df.foreground = df.WndBackground(wnd);
        df.wputch(wnd, ' ', 0, 0);
        for (0..@intCast(win.WindowWidth())) |x| {
            df.wputch(wnd, 220, @intCast(x+1), 0);
            df.wputch(wnd, 223, @intCast(x+1), 1);
        }
    }
    if (msg == df.LEFT_BUTTON) {
        _ = q.SendMessage(null, df.WAITMOUSE, 0, 0);
    } else {
        _ = q.SendMessage(null, df.WAITKEYBOARD, 0, 0);
    }
    _ = win.sendMessage(df.PAINT, 0, 0);
    if (ct.*.setting == df.ON) {
        q.PostMessage(win.getParent().win, df.COMMAND, @intFromEnum(ct.*.command), 0);
    } else {
        df.beep();
    }
}

pub fn ButtonProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    if (win.GetControl()) |ct| {
        switch (msg)    {
            df.SETFOCUS => {
                _ = root.BaseWndProc(k.BUTTON, win, msg, p1, p2);
                // ---- fall through ----
                PaintMsg(win, ct, null);
                return true;
            },
            df.PAINT => {
                const ptr:usize = @intCast(p1);
                PaintMsg(win, ct, @ptrFromInt(ptr));
                return true;
            },
            df.KEYBOARD => {
                if (p1 == '\r') {
                    // ---- fall through ----
                    LeftButtonMsg(win, msg, ct);
                    return true;
                }
            },
            df.LEFT_BUTTON => {
                LeftButtonMsg(win, msg, ct);
                return true;
            },
            df.HORIZSCROLL => {
                return true;
            },
            else => {
            }
        }
    }
    return root.BaseWndProc(k.BUTTON, win, msg, p1, p2);
}
 
