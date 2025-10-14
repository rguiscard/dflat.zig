//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub const DFlatApplication = "memopad";
const sUntitled:[:0]const u8 = "Untitled";
var wndpos:c_int = 0;

pub fn main() !void {
//    const argc: c_int = @intCast(std.os.argv.len);
    const argv = std.os.argv.ptr; // already C-compatible

    // Force zig to load, otherwise, it is lazy.
    _ = mp.video;

    if (mp.q.init_messages() == false) {
        return;
    }

    df.Argv = @ptrCast(argv);

    if (mp.cfg.Load() == false) {
        mp.cfg.config.ScreenLines = @intCast(df.SCREENHEIGHT);
    }

    var win = mp.Window.create(mp.CLASS.APPLICATION,
                        "D-Flat MemoPad",
                        0, 0, -1, -1,
                        .{.menubar = &menu.MainMenu},
                        null,
                        MemoPadProc,
                        df.MOVEABLE  |
                        df.SIZEABLE  |
                        df.HASBORDER |
                        df.MINMAXBOX |
                        df.HASSTATUSBAR);
    df.LoadHelpFile(@constCast(DFlatApplication.ptr));
    _ = win.sendMessage(df.SETFOCUS, .{.legacy=.{df.TRUE, 0}});

//    while (argc > 1)    {
//        OpenPadWindow(wnd, argv[1]);
//        --argc;
//        argv++;
//    }
    while (mp.Message.dispatch_message()) {
    }
}

// ------- window processing module for the
//                    memopad application window -----
fn MemoPadProc(win:*mp.Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
    switch(msg) {
        df.CREATE_WINDOW => {
            const rtn = mp.DefaultWndProc(win, msg, p1, p2);
            if (mp.cfg.config.InsertMode == true)
                mp.menu.SetCommandToggle(@constCast(@ptrCast(&menu.MainMenu)), .ID_INSERT);
            if (mp.cfg.config.WordWrap == true)
                mp.menu.SetCommandToggle(@constCast(@ptrCast(&menu.MainMenu)), .ID_WRAP);
            FixTabMenu();
            return rtn;
        },
        df.COMMAND => {
            const cmd:mp.Command = @enumFromInt(p1);
            switch(cmd) {
                .ID_NEW => {
                    NewFile(win);
                    return true;
                },
                .ID_OPEN => {
                    if (SelectFile(win)) {
                        return true;
                    } else |_| {
                        return false;
                    }
                },
                .ID_SAVE => {
                    if (mp.Window.inFocus) |w| {
                        SaveFile(w, false);
                        return true;
                    }
                    return false;
                },
                .ID_SAVEAS => {
                    if (mp.Window.inFocus) |w| {
                        SaveFile(w, true);
                        return true;
                    }
                    return false;
                },
                .ID_DELETEFILE => {
                    if (mp.Window.inFocus) |w| {
                        DeleteFile(w);
                        return true;
                    }
                    return false;
                },
                .ID_EXIT => {
                    const m = "Exit Memopad?";
                    if (mp.MessageBox.YesNoBox(m) == false)
                        return false;
                },
                .ID_WRAP => {
                    mp.cfg.config.WordWrap = mp.menu.GetCommandToggle(@constCast(@ptrCast(&menu.MainMenu)), .ID_WRAP);
                    return true;
                },
                .ID_INSERT => {
                    mp.cfg.config.InsertMode = mp.menu.GetCommandToggle(@constCast(@ptrCast(&menu.MainMenu)), .ID_INSERT);
                    return true;
                },
                .ID_TAB2 => {
                    mp.cfg.config.Tabs = 2;
                    FixTabMenu();
                    return true;
                },
                .ID_TAB4 => {
                    mp.cfg.config.Tabs = 4;
                    FixTabMenu();
                    return true;
                },
                .ID_TAB6 => {
                    mp.cfg.config.Tabs = 6;
                    FixTabMenu();
                    return true;
                },
                .ID_TAB8 => {
                    mp.cfg.config.Tabs = 8;
                    FixTabMenu();
                    return true;
                },
                .ID_CALENDAR => {
                    mp.Calendar.Calendar(win);
                    return true;
                },
                .ID_BARCHART => {
                    mp.BarChart.BarChart(win);
                    return true;
                },
                .ID_ABOUT => {
                    const t = "About D-Flat and the MemoPad";
                    const m =
                        \\About D-Flat and the MemoPad
                        \\   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
                        \\   ³    ÜÜÜ   ÜÜÜ     Ü    ³
                        \\   ³    Û  Û  Û  Û    Û    ³
                        \\   ³    Û  Û  Û  Û    Û    ³
                        \\   ³    Û  Û  Û  Û Û  Û    ³
                        \\   ³    ßßß   ßßß   ßß     ³
                        \\   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                        \\D-Flat implements the SAA/CUA
                        \\interface in a public domain
                        \\C language library originally
                        \\published in Dr. Dobb's Journal
                        \\    ------------------------
                        \\MemoPad is a multiple document
                        \\editor that demonstrates D-Flat
                    ;
                    _ = mp.MessageBox.MessageBox(t, m);
                    return true;
                },
                else => {
                }
            }
        },
        else => {
        }
    }
    return mp.DefaultWndProc(win, msg, p1, p2);
}

// --- The New command. Open an empty editor window ---
fn NewFile(win: *mp.Window) void {
    OpenPadWindow(win, sUntitled);
}

// --- The Open... command. Select a file  ---
fn SelectFile(win: *mp.Window) !void {
    const fspec:[:0]const u8 = "*";
    var filename = std.mem.zeroes([df.MAXPATH]u8);

    if (mp.fileopen.OpenFileDialogBox(fspec, &filename)) {
        // --- see if the document is already in a window ---
        var win1 = win.firstWindow();
        while (win1) |w1| {
            if (w1.extension) |extension| {
                const ext:[:0]const u8 = @ptrCast(extension.filename);
                if (std.mem.indexOfScalar(u8, &filename,0)) |pos| {
//                    const ff:[:0]const u8 = @ptrCast(filename[0..pos]);
//                const ext:[*c]const u8 = @ptrCast(extension);
//                if (df.strcasecmp(&filename, ext) == 0) {
                    if (std.ascii.eqlIgnoreCase(filename[0..pos], ext)) {
                        _ = w1.sendMessage(df.SETFOCUS, .{.legacy=.{df.TRUE, 0}});
                        _ = w1.sendMessage(df.RESTORE, .{.legacy=.{0, 0}});
                        return;
                    } else {
//                        _ = df.printf("ff %s %d, ext %s %d\n", ff.ptr, ff.len, ext.ptr, ext.len);
//                        while(true) {}
                    }
                }
            }
            win1 = w1.nextWindow();
        }

        const fname = @as([*:0]u8, filename[0..filename.len-1:0]);
        OpenPadWindow(win, std.mem.span(fname));
    }
}

// --- open a document window and load a file ---
pub fn OpenPadWindow(win:*mp.Window, filename: []const u8) void {
    const fname = filename;
    if (std.mem.eql(u8, sUntitled, fname) == false) {
        // check for existing
        if (std.fs.cwd().access(fname, .{.mode = .read_only})) {
            if (std.fs.cwd().statFile(fname)) |stat| {
                if (stat.kind == std.fs.File.Kind.file) {
                } else { return; }
            } else |_| { return; }
        } else |_| { return; }
    }

    var wwin = mp.watch.WatchIcon();

    wndpos += 2;
    if (wndpos == 20)
        wndpos = 2;
    var win1 = mp.Window.create(mp.CLASS.EDITBOX, // Win
                @ptrCast(fname),
                (wndpos-1)*2, wndpos, 10, 40,
                null, win, OurEditorProc,
                df.SHADOW     |
                df.MINMAXBOX  |
                df.CONTROLBOX |
                df.VSCROLLBAR |
                df.HSCROLLBAR |
                df.MOVEABLE   |
                df.HASBORDER  |
                df.SIZEABLE   |
                df.MULTILINE);

    if (std.mem.eql(u8, fname, sUntitled) == false) {
        if (mp.global_allocator.allocSentinel(u8, fname.len, 0)) |buf| {
            @memcpy(buf[0..fname.len], fname);
//            win1.win.*.extension = @ptrCast(buf.ptr);
            win1.extension = .{.filename = buf[0..fname.len]};
        } else |_| {
        }
        // wnd.extension is used to store filename.
        // it is also be used to compared already opened files.
        LoadFile(win1);
    }

    _ = wwin.sendMessage(df.CLOSE_WINDOW, .{.legacy=.{0, 0}});
    _ = win1.sendMessage(df.SETFOCUS, .{.legacy=.{df.TRUE, 0}});
}

// --- Load the notepad file into the editor text buffer ---
fn LoadFile(win: *mp.Window) void {
//    if (win.win.*.extension) |ext| {
    if (win.extension) |ext| {
//        const ptr = @as([*:0]u8, @ptrCast(ext));
//        const filename = std.mem.span(ptr);
        const filename = ext.filename;
        if (std.fs.cwd().readFileAlloc(mp.global_allocator, filename, 1_048_576)) |content| {
            defer mp.global_allocator.free(content);
            _ = win.sendTextMessage(df.SETTEXT, content, 0);
        } else |_| {
        }
    }
}

// ---------- save a file to disk ------------
fn SaveFile(win:*mp.Window, Saveas: bool) void {
    const wnd = win.win;
    const fspec:[:0]const u8 = "*";
    var filename = std.mem.zeroes([df.MAXPATH]u8);
//    if ((wnd.*.extension == null) or (Saveas == true)) {
    if ((win.extension == null) or (Saveas == true)) {
        if (mp.fileopen.SaveAsDialogBox(fspec, null, &filename)) {
//            if (wnd.*.extension) |ext| {
            if (win.extension) |ext| {
                _ = ext;
//  FIXME: free memory
//                const ptr = @as([*:0]u8, @ptrCast(ext));
//                const fname = std.mem.span(ptr);
//                mp.global_allocator.free(fname);
            }
            if (std.fs.cwd().realpathAlloc(mp.global_allocator, ".")) |_| {
                const ptr = @as([*:0]u8, @ptrCast(&filename));
                const fname = std.mem.span(ptr);
                if (mp.global_allocator.allocSentinel(u8, fname.len, 0)) |buf| {
                    @memcpy(buf[0..fname.len], fname);
//                    wnd.*.extension = @ptrCast(buf.ptr);
                    win.extension = .{.filename = buf};
                } else |_| {
                }
                win.AddTitle(@ptrCast(fname));
                _ = mp.q.SendMessage(wnd, df.BORDER, .{.legacy = .{0, 0}});
            } else |_| {
            }
        } else {
            return;
        }
    }
//    if (wnd.*.extension) |ext| {
    if (win.extension) |ext| {
        const m:[:0]const u8 = "Saving the file";
        var mwin = mp.MessageBox.MomentaryMessage(m);

//        const ptr = @as([*:0]u8, @ptrCast(ext));
//        const path = std.mem.span(ptr);
        const path = ext.filename;
        const text = @as([*:0]u8, @ptrCast(wnd.*.text));
        const data:[]const u8 = std.mem.span(text); // save data up to \0
        if (std.fs.cwd().writeFile(.{.sub_path = path, .data = data})) {
            win.TextChanged = false;
        } else |_| {
        }

        _ = mwin.sendMessage(df.CLOSE_WINDOW, .{.legacy=.{0, 0}});
    }
}

// -------- delete a file ------------
fn DeleteFile(win:*mp.Window) void {
    const wnd = win.win;
//    if (wnd.*.extension) |ext| {
    if (win.extension) |ext| {
//        const ptr = @as([*:0]u8, @ptrCast(ext));
//        const path = std.mem.span(ptr);
        const path:[:0]const u8 = @ptrCast(ext.filename);
        if (std.mem.eql(u8, path, sUntitled) == false) {
            if (std.fmt.allocPrintSentinel(mp.global_allocator, "Delete {s} ?", .{path}, 0)) |m| {
                defer mp.global_allocator.free(m);
                if (mp.MessageBox.YesNoBox(m)) {
                    if (std.fs.cwd().deleteFileZ(path)) |_| {
                    } else |_| {
                    }
                    _ = mp.q.SendMessage(wnd, df.CLOSE_WINDOW, .{.legacy = .{0, 0}});
                }
            } else |_| {
            }
        }
    }
}

fn FixTabMenu() void {
    const cp = mp.menu.GetCommandText(&menu.MainMenu, .ID_TABS);
    if (cp) |cmd| {
        if (std.mem.indexOfScalar(u8, cmd, '(')) |_| {
            if (mp.Window.inFocus) |focus| {
                if (focus.getClass() == mp.CLASS.POPDOWNMENU) {
                    _ = focus.sendMessage(df.PAINT, .{.legacy=.{0, 0}});
                }
            }
        }
//        cp = strchr(cp, '(');
//        if (cp != null) {
//            if (inFocus && (GetClass(inFocus) == POPDOWNMENU))
//                SendMessage(inFocus, PAINT, 0, 0);
//        }
    }
}

// ----- window processing module for the editboxes -----
fn OurEditorProc(win:*mp.Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) bool {
//    const wnd = win.win;
    var rtn = false;
    switch (msg) {
        df.SETFOCUS => {
            if (p1 > 0) {
                win.InsertMode = mp.menu.GetCommandToggle(@constCast(@ptrCast(&menu.MainMenu)), .ID_INSERT);
                win.WordWrapMode = mp.menu.GetCommandToggle(@constCast(@ptrCast(&menu.MainMenu)), .ID_WRAP);
            }
            rtn = mp.DefaultWndProc(win, msg, p1, p2);
            if (p1 == 0) {
                _ = win.getParent().sendMessage(df.ADDSTATUS, .{.legacy=.{0, 0}});
            } else {
                ShowPosition(win);
            }
            return rtn;
        },
        df.KEYBOARD_CURSOR => {
            rtn = mp.DefaultWndProc(win, msg, p1, p2);
            ShowPosition(win);
            return rtn;
        },
        df.COMMAND => {
            const cmd:mp.Command = @enumFromInt(p1);
            switch(cmd) {
                .ID_HELP => {
//                    const helpfile:[:0]const u8 = "MEMOPADDOC";
                    _ = mp.helpbox.DisplayHelp(win, "memopad");
                    return true;
                },
                .ID_WRAP => {
                    _ = win.getParent().sendCommandMessage(.ID_WRAP, 0);
                    win.WordWrapMode = mp.cfg.config.WordWrap;
                },
                .ID_INSERT => {
                    _ = win.getParent().sendCommandMessage(.ID_INSERT, 0);
                    win.InsertMode = mp.cfg.config.InsertMode;
                    _ = mp.q.SendMessage(null, df.SHOW_CURSOR,
                                             .{.legacy = .{if (win.InsertMode) df.TRUE else df.FALSE, 0}});
                },
                else => {
                }
            }
        },
        df.CLOSE_WINDOW => {
            if (win.TextChanged)    {
                _ = win.sendMessage(df.SETFOCUS, .{.legacy=.{df.TRUE, 0}});
//                const tl:[*c]u8 = @ptrCast(wnd.*.title);
//                const title = std.mem.span(tl);
                const title = win.title orelse "";
                if (std.fmt.allocPrintSentinel(mp.global_allocator, "{s}\nText changed. Save it ?", .{title}, 0)) |m| {
                    defer mp.global_allocator.free(m);
                    if (mp.MessageBox.YesNoBox(m)) {
                        _ = win.getParent().sendCommandMessage(.ID_SAVE, 0);
                    }
                } else |_| {
                    // error
                }
            }
            wndpos = 0;
//            if (wnd.*.extension != null)    {
//                df.free(wnd.*.extension);
//                wnd.*.extension = null;
//            }
            if (win.extension) |extension| {
//                df.free(wnd.*.extension);
                _ = extension;
                //FIXME free extension;
                win.extension = null;
            }
        },
        else => {
        }
    }
    return mp.DefaultWndProc(win, msg, p1, p2);
}

// ------ display the row and column in the statusbar ------
fn ShowPosition(win:*mp.Window) void {
    const wnd = win.win;
    const ln:u32 = @intCast(wnd.*.CurrLine);
    const cl:u32 = @intCast(wnd.*.CurrCol);
    if (std.fmt.allocPrintSentinel(mp.global_allocator, "Line:{d:4} Column: {d:2}", .{ln, cl}, 0)) |m| {
        defer mp.global_allocator.free(m);
        _ = win.getParent().sendMessage(df.ADDSTATUS, .{.legacy=.{@intCast(@intFromPtr(m.ptr)), 0}});
    } else |_| {
        // error
    }
}

pub fn PrepFileMenu(w:?*mp.Window, mnu:*mp.menus.MENU) void {
    _ = mnu;
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_SAVE);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_SAVEAS);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_DELETEFILE);
    if (w) |win| {
        if (win.getClass() == mp.CLASS.EDITBOX) {
            if (win.isMultiLine()) {
                mp.menu.ActivateCommand(&menu.MainMenu, .ID_SAVE);
                mp.menu.ActivateCommand(&menu.MainMenu, .ID_SAVEAS);
                mp.menu.ActivateCommand(&menu.MainMenu, .ID_DELETEFILE);
            }
        }
    }
}

pub fn PrepEditMenu(w:?*mp.Window, mnu:*mp.menus.MENU) void {
    _ = mnu;
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_CUT);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_COPY);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_CLEAR);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_DELETETEXT);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_PARAGRAPH);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_PASTE);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_UNDO);
    if (w) |win| {
        if (win.getClass() == mp.CLASS.EDITBOX) {
           if (win.isMultiLine()) {
               if (mp.textbox.TextBlockMarked(win)) {
                   mp.menu.ActivateCommand(&menu.MainMenu, .ID_CUT);
                   mp.menu.ActivateCommand(&menu.MainMenu, .ID_COPY);
                   mp.menu.ActivateCommand(&menu.MainMenu, .ID_CLEAR);
                   mp.menu.ActivateCommand(&menu.MainMenu, .ID_DELETETEXT);
               }
               mp.menu.ActivateCommand(&menu.MainMenu, .ID_PARAGRAPH);
               if ((win.TestAttribute(df.READONLY) == false)) {
                   if (mp.clipboard.Clipboard) |_| {
                       mp.menu.ActivateCommand(&menu.MainMenu, .ID_PASTE);
                   }
               }
               if (win.DeletedText != null)
                   mp.menu.ActivateCommand(&menu.MainMenu, .ID_UNDO);
           }
        }
    }
}

pub fn PrepSearchMenu(w:?*mp.Window, mnu:*mp.menus.MENU) void {
    _ = mnu;
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_SEARCH);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_REPLACE);
    mp.menu.DeactivateCommand(&menu.MainMenu, .ID_SEARCHNEXT);
    if (w) |win| {
        if (win.getClass() == mp.CLASS.EDITBOX) {
            if (win.isMultiLine()) {
                mp.menu.ActivateCommand(&menu.MainMenu, .ID_SEARCH);
                mp.menu.ActivateCommand(&menu.MainMenu, .ID_REPLACE);
                mp.menu.ActivateCommand(&menu.MainMenu, .ID_SEARCHNEXT);
            }
        }
    }
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
const menu = @import("MainMenu.zig");
