const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const DialogBox = @import("DialogBox.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");

fn BuildList(win:*Window, fspec:[]const u8, dirs:bool) bool {
    const wnd = win.win;
    if (wnd.*.extension) |ext| {
        const dbox:*df.DBOX = @ptrCast(@alignCast(ext));
        const control = DialogBox.FindCommand(dbox,
                        if (dirs) df.ID_DIRECTORY else df.ID_FILES, df.LISTBOX);
        if (control) |ct| {
            _ = df.cBuildList(ct, @constCast(fspec.ptr), if (dirs) df.TRUE else df.FALSE);
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
        const dbox:*df.DBOX = @ptrCast(@alignCast(ext));
        const control = DialogBox.FindCommand(dbox, df.ID_PATH, df.TEXT);
        if (control) |ct| {
            const path = std.mem.zeroes([df.MAXPATH]u8);
            const lwnd:df.WINDOW = @ptrCast(@alignCast(ct.*.wnd));
            _ = df.getcwd(@constCast(&path), path.len);
            _ = q.SendMessage(lwnd, df.SETTEXT, @intCast(@intFromPtr(&path)), 0);
            _ = q.SendMessage(lwnd, df.PAINT, 0, 0);
        }
    }
}
