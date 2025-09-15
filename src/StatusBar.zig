const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

pub fn StatusBarProc(win: *Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            _ = win.sendMessage(df.CAPTURE_CLOCK, 0, 0);
        },
        df.KEYBOARD => {
            if (p1 == df.CTRL_F4)
                return true;
        },
        df.PAINT => {
            if (df.isVisible(wnd) > 0) {
                if(root.global_allocator.alloc(u8, @intCast(win.WindowWidth()+1))) |sb| {
                    @memset(sb, ' ');
                    sb[@intCast(win.WindowWidth())] = 0;
                    const sub = "F1=Help";
                    @memcpy(sb[1..8], sub);

                    if (win.text) |text| {
                        if (std.mem.indexOfScalar(u8, text, 0)) |wlen| {
                            var len:isize = @min(wlen, win.WindowWidth()-17);
                            if (len > 0) {
                                const off:isize = @intCast(@divFloor(win.WindowWidth()-len, 2));
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

                    df.SetStandardColor(wnd);
                    df.PutWindowLine(wnd, @constCast(@ptrCast(sb.ptr)), 0, 0);
                    defer root.global_allocator.free(sb);
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
            df.SetStandardColor(wnd);
            const pp:usize = @intCast(p1);
            df.PutWindowLine(wnd, @ptrFromInt(pp), @intCast(win.WindowWidth()-8), 0);
            win.TimePosted = true;
            if (win.PrevClock) |clock| {
                _ = clock.sendMessage(msg, p1, p2);
            } else { // can it be null ?
                _ = q.SendMessage(null, msg, p1, p2);
            }
            return true;
        },
        df.CLOSE_WINDOW => {
            _ = win.sendMessage(df.RELEASE_CLOCK, 0, 0);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.STATUSBAR, win, msg, p1, p2);
}
