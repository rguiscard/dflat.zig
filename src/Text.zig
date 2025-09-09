const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

fn drawText(win:*Window) void {
    const wnd = win.win;
//    const ct = df.GetControl(wnd);
    if (win.GetControl()) |ct| {
//        if (ct == null)
//            return;
        if ((ct.*.itext == null) or (wnd.*.text != null))
            return;

        const height:usize = @intCast(ct.*.dwnd.h);
        var idx:usize = 0;

//        const ptr = @as([*:0]u8, ct.*.itext);
//        const content = std.mem.span(ptr);
        if (ct.*.itext) |content| {
            var iter = std.mem.splitScalar(u8, content, '\n');
            while (iter.next()) |line| {
                const count = std.mem.count(u8, line, &[_]u8{df.SHORTCUTCHAR});
                if (count > 0) {
                    const mlen:usize = @intCast(line.len+3*count);
                    if (root.global_allocator.allocSentinel(u8, mlen, 0)) |buf| {
                        defer root.global_allocator.free(buf);
                        _ = df.CopyCommand(buf.ptr, @constCast(line.ptr), df.FALSE, df.WndBackground(wnd));
                        _ = win.sendTextMessage(df.ADDTEXT, @constCast(buf), 0);
                    } else |_| {
                    }
                } else {
                    _ = win.sendTextMessage(df.ADDTEXT, @constCast(line), 0);
                }
                if (idx >= height)
                    break;
                idx += 1;
            }
        }
    }
}

pub fn TextProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    switch (msg)    {
        df.SETFOCUS => {
            return true;
        },
        df.LEFT_BUTTON => {
            return true;
        },
        df.PAINT => {
            drawText(win);
        },
        else => {
        }
    }
    return root.zBaseWndProc(df.TEXT, win, msg, p1, p2);
}
