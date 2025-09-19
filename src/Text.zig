const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const DialogBox = @import("DialogBox.zig");
const popdown = @import("PopDown.zig");

fn drawText(win:*Window) void {
    const wnd = win.win;
    if (win.GetControl()) |ct| {
        const ctl_text = DialogBox.getCtlWindowText(ct);
        if (ctl_text == null)
            return;

        const height:usize = @intCast(ct.*.dwnd.h);
        var idx:usize = 0;

        if (ctl_text) |text| {
            var iter = std.mem.splitScalar(u8, text, '\n'); // split do not include '\n'
            while (iter.next()) |line| {
                const count = std.mem.count(u8, line, &[_]u8{df.SHORTCUTCHAR});
                if (count > 0) {
                    const mlen:usize = @intCast(line.len+3*count);
                    if (root.global_allocator.allocSentinel(u8, mlen, 0)) |buf| {
                        @memset(buf, 0);
                        defer root.global_allocator.free(buf);
                        _ = popdown.CopyCommand(buf, line, false, df.WndBackground(wnd));
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
