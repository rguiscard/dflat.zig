const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const DialogBox = @import("DialogBox.zig");
const Dialogs = @import("Dialogs.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;

fn BuildList(win:*Window, fspec:[]const u8, dirs:bool) bool {
    const wnd = win.win;
    if (wnd.*.extension) |ext| {
        const dbox:*Dialogs.DBOX = @ptrCast(@alignCast(ext));
        const control = DialogBox.FindCommand(dbox,
                        if (dirs) c.ID_DIRECTORY else c.ID_FILES, df.LISTBOX);
        if (control) |ct| {
            if (ct.win) |cwin| {
                _ = cwin.sendMessage(df.CLEARTEXT, 0, 0);
                _ = df.cBuildList(cwin.win, @constCast(fspec.ptr), if (dirs) df.TRUE else df.FALSE);
                _ = cwin.sendMessage(df.SHOW_WINDOW, 0, 0);
            }
        }
    }
    return true;
}

pub fn BuildFileList(win:*Window, fspec:[]const u8) c_int {
    return if (BuildList(win, fspec, false)) df.TRUE else df.FALSE;
}

pub fn BuildDirectoryList(win:*Window) void {
    const star = "*";
    _ = BuildList(win, star, true);
}

pub fn BuildPathDisplay(win:*Window) void {
    const wnd = win.win;
    if (wnd.*.extension) |ext| {
        const dbox:*Dialogs.DBOX = @ptrCast(@alignCast(ext));
        const control = DialogBox.FindCommand(dbox, c.ID_PATH, df.TEXT);
        if (control) |ct| {
            const path = std.mem.zeroes([df.MAXPATH]u8);
            _ = df.getcwd(@constCast(&path), path.len);
            if (ct.win) |cwin| {
                _ = cwin.sendMessage(df.SETTEXT, @intCast(@intFromPtr(&path)), 0);
                _ = cwin.sendMessage(df.PAINT, 0, 0);
            }
        }
    }
}
