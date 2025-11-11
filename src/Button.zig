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
const cfg = @import("Config.zig");
const video = @import("Video.zig");
const console = @import("Console.zig");
const Rect = @import("Rect.zig");

fn PaintMsg(win: *Window, ct: *Dialogs.CTLWINDOW, rc: ?Rect) void {
    if (win.isVisible()) {
        if (win.TestAttribute(df.SHADOW) and (cfg.config.mono == 0)) {
            // -------- draw the button's shadow -------
            video.background = r.WndBackground(win.getParent());
            video.foreground = r.BLACK;
            for(1..@intCast(win.WindowWidth()+1)) |x| {
                video.wputch(win, 223, x, 1);
            }
            video.wputch(win, 220, win.WindowWidth(), 0);
        }
        if (DialogBox.getCtlWindowText(ct)) |itext| {
            if(root.global_allocator.allocSentinel(u8, itext.len+10, 0)) |txt| {
                defer root.global_allocator.free(txt);
                @memset(txt, 0);
                var start:usize = 0;
                if (ct.*.setting == df.OFF) {
                  txt[0] = df.CHANGECOLOR;
                  txt[1] = win.WindowColors[r.HILITE_COLOR][r.FG] | 0x80;
                  txt[2] = win.WindowColors[r.STD_COLOR][r.BG] | 0x80;
                  start = 3;
                }
                _ = popdown.CopyCommand(txt[start..],itext, (ct.*.setting == df.OFF), r.WndBackground(win));
                _ = win.sendMessage(df.CLEARTEXT, q.none);
                _ = win.sendTextMessage(df.ADDTEXT, txt);
            } else |_| {
            }
        }
        // --------- write the button's text -------
        textbox.WriteTextLine(win, rc, 0, win == Window.inFocus);
    }
}

fn LeftButtonMsg(win: *Window, msg: df.MESSAGE, ct: *Dialogs.CTLWINDOW) void {
    if (cfg.config.mono == 0) {
        // --------- draw a pushed button --------
        video.background = r.WndBackground(win.getParent());
        video.foreground = r.WndBackground(win);
        video.wputch(win, ' ', 0, 0);
        for (0..@intCast(win.WindowWidth())) |x| {
            video.wputch(win, 220, x+1, 0);
            video.wputch(win, 223, x+1, 1);
        }
    }
    if (msg == df.LEFT_BUTTON) {
        _ = q.SendMessage(null, df.WAITMOUSE, q.none);
    } else {
        _ = q.SendMessage(null, df.WAITKEYBOARD, q.none);
    }
    _ = win.sendMessage(df.PAINT, .{.paint=.{null, false}});
    if (ct.*.setting == df.ON) {
        q.PostMessage(win.parent, df.COMMAND, .{.command=.{ct.*.command, 0}});
    } else {
        console.beep();
    }
}

pub fn ButtonProc(win:*Window, msg: df.MESSAGE, params:q.Params) bool {
    if (win.GetControl()) |ct| {
        switch (msg)    {
            df.SETFOCUS => {
                _ = root.BaseWndProc(k.BUTTON, win, msg, params);
                // ---- fall through ----
                PaintMsg(win, ct, null);
                return true;
            },
            df.PAINT => {
                const rect:?Rect = params.paint[0];
                PaintMsg(win, ct, rect);
                return true;
            },
            df.KEYBOARD => {
                const p1 = params.char[0];
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
    return root.BaseWndProc(k.BUTTON, win, msg, params);
}
 
