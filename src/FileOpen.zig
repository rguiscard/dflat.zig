const std = @import("std");
const df = @import("ImportC.zig").df;
const c = @import("Commands.zig").Command;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const dir = @import("Directory.zig");

var _fileSpec:?[:0]const u8 = null;
var _srchSpec:?[:0]const u8 = null;
var _fileName:?[:0]const u8 = null;

fn set_fileSpec(text: []const u8) void {
    if (_fileSpec) |f| {
      root.global_allocator.free(f);
    }
    if (root.global_allocator.dupeZ(u8, text)) |t| {
        _fileSpec = t;
    } else |_| {
    }
}

fn set_srchSpec(text: []const u8) void {
    if (_srchSpec) |s| {
      root.global_allocator.free(s);
    }
    if (root.global_allocator.dupeZ(u8, text)) |t| {
        _srchSpec = t;
    } else |_| {
    }
}

fn set_fileName(text: []const u8) void {
    if (_fileName) |n| {
      root.global_allocator.free(n);
    }
    if (root.global_allocator.dupeZ(u8, text)) |t| {
        _fileName = t;
    } else |_| {
    }
}

// Dialog Box to select a file to open
pub fn OpenFileDialogBox(Fspec:[]const u8, Fname:[*c]u8) bool {
    var fBox = Dialogs.FileOpen;
    return DlgFileOpen(Fspec, Fspec, Fname, &fBox);
}

// Dialog Box to select a file to save as
pub fn SaveAsDialogBox(Fspec:[]const u8, Sspec:?[]const u8, Fname:[*c]u8) bool {
    var sBox = Dialogs.SaveAs;
    return DlgFileOpen(Fspec, Sspec orelse Fspec, Fname, &sBox);
}

// --------- generic file open ----------
pub fn DlgFileOpen(Fspec: []const u8, Sspec: []const u8, Fname:[*c]u8, db: *Dialogs.DBOX) bool {
    // Keep a copy of Fspec, Sspec; Fname is returned value
    set_fileSpec(Fspec);
    set_srchSpec(Sspec);

    const rtn = DialogBox.create(null, db, df.TRUE, DlgFnOpen);
    if (rtn) {
        if (_fileName) |n| {
            _ = df.strcpy(Fname, n.ptr);
        }
    }
    return rtn;
}

fn DlgFnOpen(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            const rtn = root.zDefaultWndProc(win, msg, p1, p2);
            var db:*Dialogs.DBOX = undefined;
            if (wnd.*.extension) |extension| {
                db = @ptrCast(@alignCast(extension));
                if (DialogBox.ControlWindow(db, c.ID_FILENAME)) |cwin| {
                    _ = cwin.sendMessage(df.SETTEXTLENGTH, 64, 0);
                }
            }
            return rtn;
        },
        df.INITIATE_DIALOG => {
            InitDlgBox(win);
        },
        df.COMMAND => {
            const cmd:c = @enumFromInt(p1);
            const subcmd:isize = @intCast(p2);
            switch(cmd) {
                c.ID_OK => {
                    if (subcmd == 0) {
                        var fName = std.mem.zeroes([df.MAXPATH]u8);
                        DialogBox.GetItemText(wnd, c.ID_FILENAME, &fName, df.MAXPATH);
                        set_fileName(&fName);
                        if (df.CheckAndChangeDir(&fName) > 0) {
                            std.mem.copyForwards(u8, &fName, "*");
                            set_fileName(&fName);
                        }
                        if (IncompleteFilename(&fName)) {
                            // --- no file name yet ---
                            var db:*Dialogs.DBOX = undefined;
                            if (wnd.*.extension) |extension| {
                                db = @ptrCast(@alignCast(extension));
                            }
                            set_fileSpec(&fName);
                            set_srchSpec(&fName);
                            InitDlgBox(win);
                            if (DialogBox.ControlWindow(db, c.ID_FILENAME)) |cwin| {
                                _ = cwin.sendMessage(df.SETFOCUS, df.TRUE, 0);
                            }
                            return true;
                        }
                    }
                },
                c.ID_FILES => {
                    switch (subcmd) {
                        df.ENTERFOCUS, df.LB_SELECTION => {
                            // selected a different filename
                            var fName = std.mem.zeroes([df.MAXPATH]u8);
                            DialogBox.GetDlgListText(wnd, &fName, c.ID_FILES);
                            DialogBox.PutItemText(wnd, c.ID_FILENAME, &fName);
                            set_fileName(&fName);
                        },
                        df.LB_CHOOSE => {
                            // chose a file name
                            var fName = std.mem.zeroes([df.MAXPATH]u8);
                            DialogBox.GetDlgListText(wnd, &fName, c.ID_FILES);
                            _ = win.sendCommandMessage(c.ID_OK, 0);
                            set_fileName(&fName);
                        },
                        else => {
                        }
                    }
                    return true;
                },
                c.ID_DIRECTORY => {
                    switch (subcmd) {
                        df.ENTERFOCUS => {
                            if (_fileSpec) |f| {
                                DialogBox.PutItemText(wnd, c.ID_FILENAME, @constCast(f.ptr));
                            }
                        },
                        df.LB_CHOOSE => {
                            var dd = std.mem.zeroes([df.MAXPATH]u8);
                            DialogBox.GetDlgListText(wnd, &dd, c.ID_DIRECTORY);
                            _ = df.chdir(&dd);
                            InitDlgBox(win);
                            _ = win.sendCommandMessage(c.ID_OK, 0);
                        },
                        else => {
                        }
                    }
                    return true;
                },
                else => {
                }
            }
        },
        else => {
        }
    }
    return root.zDefaultWndProc(win, msg, p1, p2);
}


//  Initialize the dialog box
fn InitDlgBox(win:*Window) void {
    const wnd = win.win;
    var sspec:[*c]u8 = null;
    var rtn = df.FALSE;
    if (_fileSpec) |f| {
        DialogBox.PutItemText(wnd, c.ID_FILENAME, @constCast(f.ptr));
    }
    if (_srchSpec) |s| {
        sspec = @constCast(s.ptr);
        rtn = dir.BuildFileList(win, s);
    }

    if (rtn == df.TRUE) {
        dir.BuildDirectoryList(win);
    }
    dir.BuildPathDisplay(win);
}

fn IncompleteFilename(s: *[df.MAXPATH]u8) bool {
    const len = s.*.len;
    if (len == 0)
        return true;
    if ((std.mem.indexOfAny(u8, s, "?*") != null) or (s[0] == 0)) {
        return true;
    }
    return false;
}
