const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const k = @import("Classes.zig").CLASS;
const Window = @import("Window.zig");

var tick:usize = 0;
const hands = [_][]const u8{" \xC0 ", " \xDA ", " \xBF ", " \xD9 "};
const bo = "\xCD";

pub fn WatchIconProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
        switch (msg) {
            df.CREATE_WINDOW => {
                tick = 0;
                const rtn = root.zDefaultWndProc(win, msg, p1, p2);
                _ = win.sendMessage(df.CAPTURE_MOUSE, 0, 0);
                _ = win.sendMessage(df.HIDE_MOUSE, 0, 0);
                _ = win.sendMessage(df.CAPTURE_KEYBOARD, 0, 0);
                _ = win.sendMessage(df.CAPTURE_CLOCK, 0, 0);
                return rtn;
            },
            df.CLOCKTICK => {
                tick = tick + 1;
                tick = tick & 3; // the same as tick % 4 for positive number
                if (win.PrevClock) |clock| {
                    _ = clock.sendMessage(msg, p1, p2);
                } else { // could clock be null ?
                    _ = df.SendMessage(null, msg, p1, p2);
                }
                // (fall through and paint)
                _ = df.SetStandardColor(wnd);
                df.writeline(wnd, @constCast(hands[tick].ptr), 1, 1, df.FALSE);
                return true;
            },
            df.PAINT => {
                _ = df.SetStandardColor(wnd);
                df.writeline(wnd, @constCast(hands[tick].ptr), 1, 1, df.FALSE);
                return true;
            },
            df.BORDER => {
                const rtn = root.zDefaultWndProc(win, msg, p1, p2);
                df.writeline(wnd, @constCast(bo.ptr), 2, 0, df.FALSE);
                return rtn;
            },
            df.MOUSE_MOVED => {
                _ = win.sendMessage(df.HIDE_WINDOW, 0, 0);
                _ = win.sendMessage(df.MOVE, p1, p2);
                _ = win.sendMessage(df.SHOW_WINDOW, 0, 0);
                return true;
            },
            df.CLOSE_WINDOW => {
                _ = win.sendMessage(df.RELEASE_CLOCK, 0, 0);
                _ = win.sendMessage(df.RELEASE_MOUSE, 0, 0);
                _ = win.sendMessage(df.RELEASE_KEYBOARD, 0, 0);
                _ = win.sendMessage(df.SHOW_MOUSE, 0, 0);
            },
            else => {
            }
        }

    return root.zDefaultWndProc(win, msg, p1, p2);
}

pub export fn WatchIcon() *Window {
    var mx:c_int = 10;
    var my:c_int = 10;
    _ = df.SendMessage(null, df.CURRENT_MOUSE_CURSOR, @intCast(@intFromPtr(&mx)), @intCast(@intFromPtr(&my)));
    const win = Window.create (
                    k.BOX,
                    null,
                    mx, my, 3, 5,
                    null, null,
                    WatchIconProc,
                    df.VISIBLE | df.HASBORDER | df.SHADOW | df.SAVESELF);
    return win;
}
