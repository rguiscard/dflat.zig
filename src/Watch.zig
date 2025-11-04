const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const k = @import("Classes.zig").CLASS;
const Window = @import("Window.zig");
const q = @import("Message.zig");
const colors = @import("Colors.zig");

var tick:usize = 0;
const hands = [_][:0]const u8{" \xC0 ", " \xDA ", " \xBF ", " \xD9 "};
const bo = "\xCD";

pub fn WatchIconProc(win:*Window, msg: df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            tick = 0;
            const rtn = root.DefaultWndProc(win, msg, params);
            _ = win.sendMessage(df.CAPTURE_MOUSE, .{.capture=.{false, null}});
            _ = win.sendMessage(df.HIDE_MOUSE, q.none);
            _ = win.sendMessage(df.CAPTURE_KEYBOARD, .{.capture=.{false, null}});
            _ = win.sendMessage(df.CAPTURE_CLOCK, q.none);
            return rtn;
            },
        df.CLOCKTICK => {
            tick = tick + 1;
            tick = tick & 3; // the same as tick % 4 for positive number
            if (win.PrevClock) |clock| {
                _ = clock.sendMessage(msg, params);
            } else { // could clock be null ?
                _ = q.SendMessage(null, msg, params);
            }
            // (fall through and paint)
            colors.SetStandardColor(win);
            win.writeline(hands[tick], 1, 1, false);
            return true;
        },
        df.PAINT => {
            colors.SetStandardColor(win);
            win.writeline(hands[tick], 1, 1, false);
            return true;
        },
        df.BORDER => {
            const rtn = root.DefaultWndProc(win, msg, params);
            win.writeline(bo, 2, 0, false);
            return rtn;
        },
        df.MOUSE_MOVED => {
            _ = win.sendMessage(df.HIDE_WINDOW, q.none);
            _ = win.sendMessage(df.MOVE, params);
            _ = win.sendMessage(df.SHOW_WINDOW, q.none);
            return true;
        },
        df.CLOSE_WINDOW => {
            _ = win.sendMessage(df.RELEASE_CLOCK, q.none);
            _ = win.sendMessage(df.RELEASE_MOUSE, .{.capture=.{false, null}});
            _ = win.sendMessage(df.RELEASE_KEYBOARD, .{.capture=.{false, null}});
            _ = win.sendMessage(df.SHOW_MOUSE, q.none);
        },
        else => {
        }
    }

    return root.DefaultWndProc(win, msg, params);
}

pub fn WatchIcon() *Window {
    var mx:usize = 10;
    var my:usize = 10;
    _ = q.SendMessage(null, df.CURRENT_MOUSE_CURSOR, .{.cursor=.{&mx, &my}});
    const win = Window.create(
                    k.BOX,
                    null,
                    mx, my, 3, 5,
                    null, null,
                    WatchIconProc,
                    df.VISIBLE | df.HASBORDER | df.SHADOW | df.SAVESELF, .{});
    return win;
}
