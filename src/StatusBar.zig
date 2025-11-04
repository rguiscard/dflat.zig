const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const k = @import("Classes.zig").CLASS;
const colors = @import("Colors.zig");

pub fn StatusBarProc(win: *Window, msg: df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            _ = win.sendMessage(df.CAPTURE_CLOCK, q.none);
        },
        df.KEYBOARD => {
            const p1 = params.char[0];
            if (p1 == df.CTRL_F4)
                return true;
        },
        df.PAINT => {
            if (win.isVisible()) {
                if(root.global_allocator.alloc(u8, @intCast(win.WindowWidth()+1))) |sb| {
                    defer root.global_allocator.free(sb);

                    @memset(sb, ' ');
                    sb[@intCast(win.WindowWidth())] = 0;
                    const sub = "F1=Help";
                    @memcpy(sb[1..8], sub);

                    if (win.gapbuf) |buf| {
                        const text = buf.toString();
                        if (text.len>0) {
                            const wlen = text.len;
                            var len:usize = @min(wlen, win.WindowWidth()-17);
                            if (len > 0) {
                                const off:usize = @divFloor(win.WindowWidth()-len, 2);
                                if (len > wlen)
                                    len = @intCast(wlen);
                                @memcpy(sb[@intCast(off)..@intCast(off+len)], text[0..@intCast(len)]);
                            }
                        }
                    }

                    if (win.TimePosted) {
                        sb[@intCast(win.WindowWidth()-8)] = 0;
                    } else {
//                        strncpy(statusbar+WindowWidth(wnd)-8, time_string, 9);
                    }

                    colors.SetStandardColor(win);
                    win.PutWindowLine(@ptrCast(sb), 0, 0);
                    return true;
                } else |_| {
                    // error
                }
//            statusbar = DFcalloc(1, WindowWidth(wnd)+1);
//                        memset(statusbar, ' ', WindowWidth(wnd));
//                        *(statusbar+WindowWidth(wnd)) = '\0';
//                        strncpy(statusbar+1, "F1=Help", 7);
//                        if (wnd->text)  {
//                                int len = min(strlen(wnd->text), WindowWidth(wnd)-17);
//                                if (len > 0)    {
//                                        int off=(WindowWidth(wnd)-len)/2;
//                                        strncpy(statusbar+off, wnd->text, len);
//                                }
//                        }
//                        if (wnd->TimePosted)
//                                *(statusbar+WindowWidth(wnd)-8) = '\0';
//                        else
//                                strncpy(statusbar+WindowWidth(wnd)-8, time_string, 9);
//            SetStandardColor(wnd);
//            PutWindowLine(wnd, statusbar, 0, 0);
//                        free(statusbar);
//                        return TRUE;
            }
        },
        df.BORDER => {
            return true;
        },
        df.CLOCKTICK => {
            const p1 = params.legacy[0];
            colors.SetStandardColor(win);
            const pp:usize = @intCast(p1);
            const str:[*c]u8 = @ptrFromInt(pp);
            win.PutWindowLine(std.mem.span(str), win.WindowWidth()-8, 0);
            win.TimePosted = true;
            if (win.PrevClock) |clock| {
                _ = clock.sendMessage(msg, params);
            } else { // can it be null ?
                _ = q.SendMessage(null, msg, params);
            }
            return true;
        },
        df.CLOSE_WINDOW => {
            _ = win.sendMessage(df.RELEASE_CLOCK, q.none);
        },
        else => {
        }
    }
    return root.BaseWndProc(k.STATUSBAR, win, msg, params);
}
