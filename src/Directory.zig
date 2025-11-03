const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const DialogBox = @import("DialogBox.zig");
const Dialogs = @import("Dialogs.zig");
const Window = @import("Window.zig");
const q = @import("Message.zig");
const c = @import("Commands.zig").Command;
const k = @import("Classes.zig").CLASS;

// Check if fspec is a directory, if so chdir and return TRUE
pub fn CheckAndChangeDir(fspec:[]const u8) bool {
    const cwd = std.fs.cwd();
    const subdir:[:0]u8 = @ptrCast(@constCast(fspec));
    if (cwd.openDirZ(subdir, .{})) |d| {
        var dd = @constCast(&d);
        defer dd.close();
        if (d.setAsCwd()) {
            return true;
        } else |_| {}
    } else |_| {
    }
    return false;
}

fn BuildList(win:*Window, fspec:[]const u8, dirs:bool) bool {
    if (win.extension) |extension| {
        const dbox:*Dialogs.DBOX = extension.dbox;
        const control = DialogBox.FindCommand(dbox,
                        if (dirs) c.ID_DIRECTORY else c.ID_FILES, k.LISTBOX);
        if (control) |ct| {
            if (ct.win) |cwin| {
                _ = cwin.sendMessage(df.CLEARTEXT, q.none);
//                _ = df.cBuildList(cwin.win, @constCast(fspec.ptr), if (dirs) df.TRUE else df.FALSE);
                _ = fspec;
                const cwd = std.fs.cwd();
                if (cwd.openDir(".", .{ .access_sub_paths = false, .iterate = true })) |*dir| {
                    defer @constCast(dir).close();
                    var iterator = dir.iterate();
                    if (dirs) {
                        // add up directory
                        _ = cwin.sendTextMessage(df.ADDTEXT, "..");
                    }
                    while (true) {
                        if (iterator.next()) |iter| {
                            if (iter) |entry| {
                                if (dirs and entry.kind == .directory) {
                                    _ = cwin.sendTextMessage(df.ADDTEXT, entry.name);
                                } else if (!dirs and entry.kind == .file) {
                                    _ = cwin.sendTextMessage(df.ADDTEXT, entry.name);
                                }
                            } else {
                                break;
                            }
                        } else |_| {
                            break;
                        }
                    }
                } else |_| {
                }
                _ = cwin.sendMessage(df.SHOW_WINDOW, q.none);
            }
        }
    }
    return true;
}

pub fn BuildFileList(win:*Window, fspec:[]const u8) bool {
    return BuildList(win, fspec, false);
}

pub fn BuildDirectoryList(win:*Window) void {
    const star = "*";
    _ = BuildList(win, star, true);
}

pub fn BuildPathDisplay(win:*Window) void {
    if (win.extension) |extension| {
        const dbox:*Dialogs.DBOX = extension.dbox;
        const control = DialogBox.FindCommand(dbox, c.ID_PATH, k.TEXT);
        if (control) |ct| {
            const path = std.mem.zeroes([df.MAXPATH]u8);
            const cwd = std.fs.cwd();
            if (cwd.realpath(".", @constCast(&path))) |pp| {
    //            _ = df.getcwd(@constCast(&path), path.len);
                if (ct.win) |cwin| {
//                    _ = cwin.sendTextMessage(df.SETTEXT, @constCast(&path));
                    _ = cwin.sendTextMessage(df.SETTEXT, @constCast(pp));
                    _ = cwin.sendMessage(df.PAINT, .{.paint=.{null, false}});
                }
            } else |_| {}
        }
    }
}
