//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

pub const df = @import("ImportC.zig").df;
pub const dialogs = @import("Dialogs.zig");
pub const menus = @import("Menus.zig");
pub const Window = @import("Window.zig");
pub const Message = @import("Message.zig");
pub const Klass = @import("Classes.zig");
pub const BarChart = @import("BarChart.zig");
pub const Calendar = @import("Calendar.zig");
pub const list = @import("Lists.zig");
pub const watch = @import("Watch.zig");
pub const SystemMenu = @import("SystemMenu.zig");
pub const WndProc = @import("WndProc.zig");
pub const DialogBox = @import("DialogBox.zig");
pub const MessageBox = @import("MessageBox.zig");
pub const fileopen = @import("FileOpen.zig");
pub const helpbox = @import("HelpBox.zig");

pub const q = @import("Message.zig");

pub const global_allocator = std.heap.c_allocator;

pub export fn BaseWndProc(klass: df.CLASS, wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    if (Window.get_zin(wnd)) |zin| {
        const rtn = zBaseWndProc(klass, zin, msg, p1, p2);
        return if (rtn) df.TRUE else df.FALSE;
    }
    return df.FALSE;
    // Is it possible that wnd is null ?
}

pub export fn DefaultWndProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    if (Window.get_zin(wnd)) |zin| {
        const rtn = zDefaultWndProc(zin, msg, p1, p2);
        return if (rtn) df.TRUE else df.FALSE;
    }
    return df.FALSE;
    // Is it possible that wnd is null ?
}

pub fn zBaseWndProc(klass: df.CLASS, win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const base_class = Klass.defs[@intCast(klass)][1]; // base
    const index:c_int = @intFromEnum(base_class);
    if (Klass.defs[@intCast(index)][2]) |proc| { // wndproc
        return proc(win, msg, p1, p2);
    }
    return false;
}

pub fn zDefaultWndProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const klass = win.win.*.Class;
    if (Klass.defs[@intCast(klass)][2]) |proc| { // wndproc
        return proc(win, msg, p1, p2);
    }
    return zBaseWndProc(klass, win, msg, p1, p2);
}

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
