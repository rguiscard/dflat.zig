const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const q = @import("Message.zig");
const Window = @import("Window.zig");

fn PaintMsg(win: *Window, ct: *df.CTLWINDOW, rc: ?*df.RECT) void {
    const wnd = win.win;
    if (df.isVisible(wnd) > 0) {
        if (win.TestAttribute(df.SHADOW) and (df.cfg.mono == 0)) {
            // -------- draw the button's shadow -------
            df.background = df.WndBackground(Window.GetParent(wnd));
            df.foreground = df.BLACK;
            for(1..@intCast(win.WindowWidth()+1)) |x| {
                df.wputch(wnd, 223, @intCast(x), 1);
            }
            df.wputch(wnd, 220, @intCast(win.WindowWidth()), 0);
        }
        if (ct.*.itext != null) {
            if(root.global_allocator.allocSentinel(u8, df.strlen(ct.*.itext)+10, 0)) |txt| {
                defer root.global_allocator.free(txt);
                @memset(txt, 0);
                var start:usize = 0;
                if (ct.*.setting == df.OFF) {
                  txt[0] = df.CHANGECOLOR;
                  txt[1] = wnd.*.WindowColors[df.HILITE_COLOR][df.FG] | 0x80;
                  txt[2] = wnd.*.WindowColors[df.STD_COLOR][df.BG] | 0x80;
                  start = 3;
                }
                _ = df.CopyCommand(&txt[start],ct.*.itext,if (ct.*.setting == df.OFF) 1 else 0, df.WndBackground(wnd));
                _ = win.sendMessage(df.CLEARTEXT, 0, 0);
                _ = win.sendMessage(df.ADDTEXT, @intCast(@intFromPtr(txt.ptr)), 0);
            } else |_| {
            }
        }
        // --------- write the button's text -------
        df.WriteTextLine(wnd, rc, 0, if (wnd == df.inFocus) 1 else 0 );
    }
}

fn LeftButtonMsg(win: *Window, msg: df.MESSAGE, ct: *df.CTLWINDOW) void {
    const wnd = win.win;
    if (df.cfg.mono == 0) {
        // --------- draw a pushed button --------
        df.background = df.WndBackground(Window.GetParent(wnd));
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
        q.PostMessage(Window.GetParent(wnd), df.COMMAND, ct.*.command, 0);
    } else {
        df.beep();
    }
}

pub fn ButtonProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    const ct = df.GetControl(wnd);
    if (ct != null)    {
        switch (msg)    {
            df.SETFOCUS => {
                _ = root.zBaseWndProc(df.BUTTON, win, msg, p1, p2);
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
    return root.zBaseWndProc(df.BUTTON, win, msg, p1, p2);
}
 
