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
pub const CLASS = @import("Classes.zig").CLASS;
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
pub const menu = @import("Menu.zig");
pub const clipboard = @import("Clipboard.zig");
pub const video = @import("Video.zig");
pub const app = @import("Application.zig");
pub const Command = @import("Commands.zig").Command;
pub const q = @import("Message.zig");
pub const Colors = @import("Colors.zig");
pub const textbox = @import("TextBox.zig");
pub const cfg = @import("Config.zig");

pub const global_allocator = std.heap.c_allocator;

// for transition
pub export const ID_HELPTEXT:c_int = @intFromEnum(Command.ID_HELPTEXT);
pub export const POPDOWNMENU:c_int = @intFromEnum(CLASS.POPDOWNMENU);
pub export const MENUBAR:c_int = @intFromEnum(CLASS.MENUBAR);

pub export fn DefaultWndProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    if (Window.get_zin(wnd)) |zin| {
        const rtn = zDefaultWndProc(zin, msg, p1, p2);
        return if (rtn) df.TRUE else df.FALSE;
    }
    return df.FALSE;
    // Is it possible that wnd is null ?
}

pub fn BaseWndProc(klass: CLASS, win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const base_idx:usize = @intCast(@intFromEnum(klass));
    const base_class = Klass.defs[base_idx][1]; // base

    const idx:usize = @intCast(@intFromEnum(base_class));
    if (Klass.defs[idx][2]) |proc| { // wndproc
        return proc(win, msg, p1, p2);
    }
    return false;
}

pub fn zDefaultWndProc(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const klass = win.Class;
    const idx:usize = @intCast(@intFromEnum(klass));
    if (Klass.defs[idx][2]) |proc| { // wndproc
        return proc(win, msg, p1, p2);
    }
    return BaseWndProc(klass, win, msg, p1, p2);
}

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
