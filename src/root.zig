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

pub const global_allocator = std.heap.c_allocator;

pub export fn BaseWndProc(klass: df.CLASS, wnd: df.WINDOW, mesg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    return zBaseWndProc(klass, wnd, mesg, p1, p2);
}

pub export fn DefaultWndProc(wnd: df.WINDOW, mesg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    return zDefaultWndProc(wnd, mesg, p1, p2);
}

pub fn zBaseWndProc(klass: df.CLASS, wnd: df.WINDOW, mesg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    const base_class = Klass.classdefs[@intCast(klass)][1]; // base
    const index:c_int = @intFromEnum(base_class);
    if (Klass.classdefs[@intCast(index)][2]) |proc| { // wndproc
        return proc(wnd, mesg, p1, p2);
    }
    return df.FALSE;
}

pub fn zDefaultWndProc(wnd: df.WINDOW, mesg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    const klass = wnd.*.Class;
    if (Klass.classdefs[@intCast(klass)][2]) |proc| { // wndproc
        return proc(wnd, mesg, p1, p2);
    }
    return zBaseWndProc(klass, wnd, mesg, p1, p2);
}

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
