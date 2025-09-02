const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");

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
pub fn DlgFileOpen(Fspec: []const u8, Sspec: []const u8, Fname:[*c]u8, db: *df.DBOX) bool {
    // Keep a copy of Fspec, Sspec; Fname is returned value
    set_fileSpec(Fspec);
    set_srchSpec(Sspec);

//    var box = DialogBox.init(@constCast(db));
//    const rtn = box.create(null, true, DlgFnOpen);
    const rtn = DialogBox.DialogBox(null, db, df.TRUE, DlgFnOpen);
    if (rtn>0) {
        if (_fileName) |n| {
            _ = df.strcpy(Fname, n.ptr);
        }
    }
    return if (rtn>0) true else false;
}

fn DlgFnOpen(win:*Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    const wnd = win.win;
    switch (msg) {
        df.CREATE_WINDOW => {
            const rtn = root.zDefaultWndProc(win, msg, p1, p2);
            var db:*df.DBOX = undefined;
            if (wnd.*.extension) |extension| {
                db = @ptrCast(@alignCast(extension));
                const cwnd = df.ControlWindow(db, df.ID_FILENAME);
                _ = df.SendMessage(cwnd, df.SETTEXTLENGTH, 64, 0);
            }
            return rtn;
        },
        df.INITIATE_DIALOG => {
            InitDlgBox(win);
        },
        df.COMMAND => {
            const cmd:isize = @intCast(p1);
            const subcmd:isize = @intCast(p2);
            switch(cmd) {
                df.ID_OK => {
                    if (subcmd == 0) {
                        var fName = std.mem.zeroes([df.MAXPATH]u8);
                        df.GetItemText(wnd, df.ID_FILENAME, &fName, df.MAXPATH);
                        set_fileName(&fName);
                        if (df.CheckAndChangeDir(&fName) > 0) {
                            std.mem.copyForwards(u8, &fName, "*");
                            set_fileName(&fName);
                        }
                        if (IncompleteFilename(&fName)) {
                            // --- no file name yet ---
                            var db:*df.DBOX = undefined;
                            if (wnd.*.extension) |extension| {
                                db = @ptrCast(@alignCast(extension));
                            }
                            const cwnd = df.ControlWindow(db, df.ID_FILENAME);
                            set_fileSpec(&fName);
                            set_srchSpec(&fName);
                            InitDlgBox(win);
                            _ = df.SendMessage(cwnd, df.SETFOCUS, df.TRUE, 0);
                            return true;
                        }
                    }
                },
                df.ID_FILES => {
                    switch (subcmd) {
                        df.ENTERFOCUS, df.LB_SELECTION => {
                            // selected a different filename
                            var fName = std.mem.zeroes([df.MAXPATH]u8);
                            df.GetDlgListText(wnd, &fName, df.ID_FILES);
                            df.PutItemText(wnd, df.ID_FILENAME, &fName);
                            set_fileName(&fName);
                        },
                        df.LB_CHOOSE => {
                            // chose a file name
                            var fName = std.mem.zeroes([df.MAXPATH]u8);
                            df.GetDlgListText(wnd, &fName, df.ID_FILES);
                            _ = df.SendMessage(wnd, df.COMMAND, df.ID_OK, 0);
                            set_fileName(&fName);
                        },
                        else => {
                        }
                    }
                    return true;
                },
                df.ID_DIRECTORY => {
                    switch (subcmd) {
                        df.ENTERFOCUS => {
                            if (_fileSpec) |f| {
                                df.PutItemText(wnd, df.ID_FILENAME, @constCast(f.ptr));
                            }
                        },
                        df.LB_CHOOSE => {
                            var dd = std.mem.zeroes([df.MAXPATH]u8);
                            df.GetDlgListText(wnd, &dd, df.ID_DIRECTORY);
                            _ = df.chdir(&dd);
                            InitDlgBox(win);
                            _ = df.SendMessage(wnd, df.COMMAND, df.ID_OK, 0);
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
    if (_fileSpec) |f| {
        df.PutItemText(wnd, df.ID_FILENAME, @constCast(f.ptr));
    }
    if (_srchSpec) |s| {
        sspec = @constCast(s.ptr);
    }

    const rtn = df.BuildFileList(wnd, sspec);
    if (rtn == df.TRUE) {
        df.BuildDirectoryList(wnd);
    }
    df.BuildPathDisplay(wnd);
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
