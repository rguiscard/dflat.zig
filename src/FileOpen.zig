const std = @import("std");
const df = @import("ImportC.zig").df;
const c = @import("Commands.zig").Command;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const dir = @import("Directory.zig");
const q = @import("Message.zig");

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

fn DlgFnOpen(win:*Window, msg: df.MESSAGE, params:q.Params) bool {
    switch (msg) {
        df.CREATE_WINDOW => {
            const rtn = root.DefaultWndProc(win, msg, params);
            if (win.extension) |extension| {
                const db:*Dialogs.DBOX = extension.dbox;
                if (DialogBox.ControlWindow(db, .ID_FILENAME)) |cwin| {
                    _ = cwin.sendMessage(df.SETTEXTLENGTH, .{.legacy=.{64, 0}});
                }
            }
            return rtn;
        },
        df.INITIATE_DIALOG => {
            InitDlgBox(win);
        },
        df.COMMAND => {
            const p1 = params.legacy[0];
            const p2 = params.legacy[1];
            const cmd:c = @enumFromInt(p1);
            const subcmd:isize = @intCast(p2);
            switch(cmd) {
                .ID_OK => {
                    if (subcmd == 0) {
                        var fName = std.mem.zeroes([df.MAXPATH]u8);
                        DialogBox.GetItemText(win, c.ID_FILENAME, &fName, df.MAXPATH);
                        set_fileName(&fName);
                        if (df.CheckAndChangeDir(&fName) > 0) {
                            std.mem.copyForwards(u8, &fName, "*");
                            set_fileName(&fName);
                        }
                        if (IncompleteFilename(&fName)) {
                            // --- no file name yet ---
                            if (win.extension) |extension| {
                                const db:*Dialogs.DBOX = extension.dbox;
                                set_fileSpec(&fName);
                                set_srchSpec(&fName);
                                InitDlgBox(win);
                                if (DialogBox.ControlWindow(db, c.ID_FILENAME)) |cwin| {
                                    _ = cwin.sendMessage(df.SETFOCUS, .{.legacy=.{df.TRUE, 0}});
                                }
                            }
                            return true;
                        }
                    }
                },
                .ID_FILES => {
                    switch (subcmd) {
                        df.ENTERFOCUS, df.LB_SELECTION => {
                            // selected a different filename
                            var fName = std.mem.zeroes([df.MAXPATH]u8);
                            DialogBox.GetDlgListText(win, &fName, c.ID_FILES);
                            DialogBox.PutItemText(win, c.ID_FILENAME, &fName);
                            set_fileName(&fName);
                        },
                        df.LB_CHOOSE => {
                            // chose a file name
                            var fName = std.mem.zeroes([df.MAXPATH]u8);
                            DialogBox.GetDlgListText(win, &fName, c.ID_FILES);
                            _ = win.sendCommandMessage(c.ID_OK, 0);
                            set_fileName(&fName);
                        },
                        else => {
                        }
                    }
                    return true;
                },
                .ID_DIRECTORY => {
                    switch (subcmd) {
                        df.ENTERFOCUS => {
                            if (_fileSpec) |f| {
                                DialogBox.PutItemText(win, c.ID_FILENAME, @constCast(f.ptr));
                            }
                        },
                        df.LB_CHOOSE => {
                            var dd = std.mem.zeroes([df.MAXPATH]u8);
                            DialogBox.GetDlgListText(win, &dd, c.ID_DIRECTORY);
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
    return root.DefaultWndProc(win, msg, params);
}


//  Initialize the dialog box
fn InitDlgBox(win:*Window) void {
    var sspec:[*c]u8 = null;
    var rtn = df.FALSE;
    if (_fileSpec) |f| {
        DialogBox.PutItemText(win, .ID_FILENAME, @constCast(f.ptr));
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
