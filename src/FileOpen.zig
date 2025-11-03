const std = @import("std");
const df = @import("ImportC.zig").df;
const c = @import("Commands.zig").Command;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const dir = @import("Directory.zig");
const q = @import("Message.zig");

var _fileSpecBuf = [_]u8{0}**df.MAXPATH;
var _srchSpecBuf = [_]u8{0}**df.MAXPATH;
var _fileNameBuf = [_]u8{0}**df.MAXPATH;

fn nameOfFile(s: []u8) []const u8 {
    if (std.mem.indexOfScalar(u8, s, 0)) |pos| {
        return s[0..pos+1];
    }
    return &.{};
}

var _fileSpec:[]const u8 = &.{};
var _srchSpec:[]const u8 = &.{};
var _fileName:[]const u8 = &.{};

fn set_fileSpec(text: []const u8) void {
    @memset(&_fileSpecBuf, 0);
    @memcpy(_fileSpecBuf[0..text.len], text);
    _fileSpec = nameOfFile(&_fileSpecBuf);
}

fn set_srchSpec(text: []const u8) void {
    @memset(&_srchSpecBuf, 0);
    @memcpy(_srchSpecBuf[0..text.len], text);
    _srchSpec = nameOfFile(&_srchSpecBuf);
}

fn set_fileName(text: []const u8) void {
    @memset(&_fileNameBuf, 0);
    @memcpy(_fileNameBuf[0..text.len], text);
    _fileName = nameOfFile(&_fileNameBuf);
}

//fn set_srchSpec(text: []const u8) void {
//    if (_srchSpec) |s| {
//      root.global_allocator.free(s);
//    }
//    if (root.global_allocator.dupeZ(u8, text)) |t| {
//        _srchSpec = t;
//    } else |_| {
//    }
//}

//fn set_fileName(text: []const u8) void {
//    if (_fileName) |n| {
//      root.global_allocator.free(n);
//    }
//    if (root.global_allocator.dupeZ(u8, text)) |t| {
//        _fileName = t;
//    } else |_| {
//    }
//}

// Dialog Box to select a file to open
pub fn OpenFileDialogBox(Fspec:[]const u8, Fname:[]u8) bool {
    var fBox = Dialogs.FileOpen;
    return DlgFileOpen(Fspec, Fspec, Fname, &fBox);
}

// Dialog Box to select a file to save as
pub fn SaveAsDialogBox(Fspec:[]const u8, Sspec:?[]const u8, Fname:[]u8) bool {
    var sBox = Dialogs.SaveAs;
    return DlgFileOpen(Fspec, Sspec orelse Fspec, Fname, &sBox);
}

// --------- generic file open ----------
pub fn DlgFileOpen(Fspec: []const u8, Sspec: []const u8, Fname:[]u8, db: *Dialogs.DBOX) bool {
    // Keep a copy of Fspec, Sspec; Fname is returned value
    set_fileSpec(Fspec);
    set_srchSpec(Sspec);

    const rtn = DialogBox.create(null, db, df.TRUE, DlgFnOpen);
    if (rtn) {
        if (_fileName.len > 0) {
            @memcpy(Fname[0.._fileName.len], _fileName);
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
                    _ = cwin.sendMessage(df.SETTEXTLENGTH, .{.usize=64});
                }
            }
            return rtn;
        },
        df.INITIATE_DIALOG => {
            InitDlgBox(win);
        },
        df.COMMAND => {
            const cmd:c = params.command[0];
            const subcmd:usize = params.command[1];
            switch(cmd) {
                .ID_OK => {
                    if (subcmd == 0) {
                        @memset(&_fileNameBuf, 0);
                        DialogBox.GetItemText(win, c.ID_FILENAME, &_fileNameBuf, @intCast(df.MAXPATH));
                        _fileName = nameOfFile(&_fileNameBuf);
                        if (dir.CheckAndChangeDir(_fileName)) {
                            @memcpy(_fileNameBuf[0..1], "*");
                            _fileName = nameOfFile(&_fileNameBuf);
                        }
                        if (IncompleteFilename(_fileName)) {
                            // --- no file name yet ---
                            if (win.extension) |extension| {
                                const db:*Dialogs.DBOX = extension.dbox;
                                set_fileSpec(_fileName);
                                set_srchSpec(_fileName);
                                InitDlgBox(win);
                                if (DialogBox.ControlWindow(db, c.ID_FILENAME)) |cwin| {
                                    _ = cwin.sendMessage(df.SETFOCUS, .{.yes=true});
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
                            @memset(&_fileNameBuf, 0);
                            DialogBox.GetDlgListText(win, &_fileNameBuf, c.ID_FILES);
                            DialogBox.PutItemText(win, c.ID_FILENAME, &_fileNameBuf);
                            _fileName = nameOfFile(&_fileNameBuf);
                        },
                        df.LB_CHOOSE => {
                            // chose a file name
                            @memset(&_fileNameBuf, 0);
                            DialogBox.GetDlgListText(win, &_fileNameBuf, c.ID_FILES);
                            _ = win.sendCommandMessage(c.ID_OK, 0);
                            _fileName = nameOfFile(&_fileNameBuf);
                        },
                        else => {
                        }
                    }
                    return true;
                },
                .ID_DIRECTORY => {
                    switch (subcmd) {
                        df.ENTERFOCUS => {
                            if (_fileSpec.len > 0) {
                                DialogBox.PutItemText(win, c.ID_FILENAME, &_fileSpecBuf);
                            }
                        },
                        df.LB_CHOOSE => {
                            var dd = std.mem.zeroes([df.MAXPATH]u8);
                            DialogBox.GetDlgListText(win, dd[0..df.MAXPATH], c.ID_DIRECTORY);
                            if (std.mem.indexOfScalar(u8, &dd, 0)) |pos| {
                                _ = dir.CheckAndChangeDir(dd[0..pos+1]);
                            }
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
    var rtn = false;
    if (_fileSpec.len > 0) {
        DialogBox.PutItemText(win, .ID_FILENAME, &_fileSpecBuf);
    }
    if (_srchSpec.len > 0) {
        rtn = dir.BuildFileList(win, &_srchSpecBuf);
    }

    if (rtn) {
        dir.BuildDirectoryList(win);
    }
    dir.BuildPathDisplay(win);
}

fn IncompleteFilename(s: []const u8) bool {
    const len = s.len;
    if (len == 0)
        return true;
    if ((std.mem.indexOfAny(u8, s, "?*") != null) or (s[0] == 0)) {
        return true;
    }
    return false;
}
