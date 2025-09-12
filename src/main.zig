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
    _ = mp.list;
    _ = mp.SystemMenu;
    _ = mp.menu;
    _ = mp.video;

    if (mp.q.init_messages() == false) {
        return;
    }

    df.Argv = @ptrCast(argv);

    if (df.LoadConfig() == df.FALSE) {
        df.cfg.ScreenLines = df.SCREENHEIGHT;
    }

    var win = mp.Window.create(df.APPLICATION,
                        "D-Flat MemoPad",
                        0, 0, -1, -1,
                        @constCast(@ptrCast(&mp.menus.MainMenu)),
                        null,
                        MemoPadProc,
                        df.MOVEABLE  |
                        df.SIZEABLE  |
                        df.HASBORDER |
                        df.MINMAXBOX |
                        df.HASSTATUSBAR);
    df.LoadHelpFile(@constCast(DFlatApplication.ptr));
    _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);

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
            const rtn = mp.zDefaultWndProc(win, msg, p1, p2);
            if (df.cfg.InsertMode == df.TRUE)
                df.SetCommandToggle(@constCast(@ptrCast(&mp.menus.MainMenu)), df.ID_INSERT);
            if (df.cfg.WordWrap == df.TRUE)
                df.SetCommandToggle(@constCast(@ptrCast(&mp.menus.MainMenu)), df.ID_WRAP);
            FixTabMenu();
            return rtn;
        },
        df.COMMAND => {
            switch(p1) {
                df.ID_NEW => {
                    NewFile(win);
                    return true;
                },
                df.ID_OPEN => {
                    if (SelectFile(win)) {
                        return true;
                    } else |_| {
                        return false;
                    }
                },
                df.ID_SAVE => {
                    if (mp.Window.get_zin(df.inFocus)) |w| {
                        SaveFile(w, false);
                        return true;
                    }
                    return false;
                },
                df.ID_SAVEAS => {
                    if (mp.Window.get_zin(df.inFocus)) |w| {
                        SaveFile(w, true);
                        return true;
                    }
                    return false;
                },
                df.ID_DELETEFILE => {
                    DeleteFile(df.inFocus);
                    return true;
                },
                df.ID_EXIT => {
                    const m = "Exit Memopad?";
                    if (mp.MessageBox.YesNoBox(m) == false)
                        return false;
                },
                df.ID_WRAP => {
                    df.cfg.WordWrap = df.GetCommandToggle(@constCast(@ptrCast(&mp.menus.MainMenu)), df.ID_WRAP);
                    return true;
                },
                df.ID_INSERT => {
                    df.cfg.InsertMode = df.GetCommandToggle(@constCast(@ptrCast(&mp.menus.MainMenu)), df.ID_INSERT);
                    return true;
                },
                df.ID_TAB2 => {
                    df.cfg.Tabs = 2;
                    FixTabMenu();
                    return true;
                },
                df.ID_TAB4 => {
                    df.cfg.Tabs = 4;
                    FixTabMenu();
                    return true;
                },
                df.ID_TAB6 => {
                    df.cfg.Tabs = 6;
                    FixTabMenu();
                    return true;
                },
                df.ID_TAB8 => {
                    df.cfg.Tabs = 8;
                    FixTabMenu();
                    return true;
                },
                df.ID_CALENDAR => {
                    mp.Calendar.Calendar(win);
                    return true;
                },
                df.ID_BARCHART => {
                    mp.BarChart.BarChart(win);
                    return true;
                },
                df.ID_ABOUT => {
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
    return mp.zDefaultWndProc(win, msg, p1, p2);
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
            if (w1.win.*.extension) |extension| {
                const ext:[*c]const u8 = @ptrCast(extension);
                if (df.strcasecmp(&filename, ext) == 0) {
                    _ = w1.sendMessage(df.SETFOCUS, df.TRUE, 0);
                    _ = w1.sendMessage(df.RESTORE, 0, 0);
                    return;
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
    var win1 = mp.Window.create(df.EDITBOX, // Win
                fname,
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
            win1.win.*.extension = @ptrCast(buf.ptr);
        } else |_| {
        }
        // wnd.extension is used to store filename.
        // it is also be used to compared already opened files.
        LoadFile(win1);
    }

    _ = wwin.sendMessage(df.CLOSE_WINDOW, 0, 0);
    _ = win1.sendMessage(df.SETFOCUS, df.TRUE, 0);
}

// --- Load the notepad file into the editor text buffer ---
fn LoadFile(win: *mp.Window) void {
    if (win.win.*.extension) |ext| {
        const ptr = @as([*:0]u8, @ptrCast(ext));
        const filename = std.mem.span(ptr);
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
    if ((wnd.*.extension == null) or (Saveas == true)) {
        if (mp.fileopen.SaveAsDialogBox(fspec, null, &filename)) {
            if (wnd.*.extension) |ext| {
                const ptr = @as([*:0]u8, @ptrCast(ext));
                const fname = std.mem.span(ptr);
                mp.global_allocator.free(fname);
            }
            if (std.fs.cwd().realpathAlloc(mp.global_allocator, ".")) |_| {
                const ptr = @as([*:0]u8, @ptrCast(&filename));
                const fname = std.mem.span(ptr);
                if (mp.global_allocator.allocSentinel(u8, fname.len, 0)) |buf| {
                    @memcpy(buf[0..fname.len], fname);
                    wnd.*.extension = @ptrCast(buf.ptr);
                } else |_| {
                }
//                df.AddTitle(wnd, df.NameComponent(&filename));
                df.AddTitle(wnd, ptr);
                _ = df.SendMessage(wnd, df.BORDER, 0, 0);
            } else |_| {
            }
        } else {
            return;
        }
    }
    if (wnd.*.extension) |ext| {
        const m:[:0]const u8 = "Saving the file";
        var mwin = mp.MessageBox.MomentaryMessage(m);

        const ptr = @as([*:0]u8, @ptrCast(ext));
        const path = std.mem.span(ptr);
        const text = @as([*:0]u8, @ptrCast(wnd.*.text));
        const data:[]const u8 = std.mem.span(text); // save data up to \0
        if (std.fs.cwd().writeFile(.{.sub_path = path, .data = data})) {
            wnd.*.TextChanged = df.FALSE;
        } else |_| {
        }

        _ = mwin.sendMessage(df.CLOSE_WINDOW, 0, 0);
    }
}

// -------- delete a file ------------
fn DeleteFile(wnd:df.WINDOW) void {
    if (wnd.*.extension) |ext| {
        const ptr = @as([*:0]u8, @ptrCast(ext));
        const path = std.mem.span(ptr);
        if (std.mem.eql(u8, path, sUntitled) == false) {
            if (std.fmt.allocPrintSentinel(mp.global_allocator, "Delete {s} ?", .{path}, 0)) |m| {
                defer mp.global_allocator.free(m);
                if (mp.MessageBox.YesNoBox(m)) {
                    if (std.fs.cwd().deleteFileZ(path)) |_| {
                    } else |_| {
                    }
                    _ = mp.q.SendMessage(wnd, df.CLOSE_WINDOW, 0, 0);
                }
            } else |_| {
            }
        }
    }
}

fn FixTabMenu() void {
    const cp:[*c]u8 = df.GetCommandText(&df.MainMenu, df.ID_TABS);
    if (cp) |c| {
        const cmd = std.mem.span(c);
        if (std.mem.indexOfScalar(u8, cmd, '(')) |_| {
            if ((df.inFocus != 0) and (df.GetClass(df.inFocus) == df.POPDOWNMENU)) {
                _ = mp.q.SendMessage(df.inFocus, df.PAINT, 0, 0);
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
    const wnd = win.win;
    var rtn = false;
    switch (msg) {
        df.SETFOCUS => {
            if (p1 > 0) {
                wnd.*.InsertMode = df.GetCommandToggle(@constCast(@ptrCast(&mp.menus.MainMenu)), df.ID_INSERT);
                wnd.*.WordWrapMode = df.GetCommandToggle(@constCast(@ptrCast(&mp.menus.MainMenu)), df.ID_WRAP);
            }
            rtn = mp.zDefaultWndProc(win, msg, p1, p2);
            if (p1 == 0) {
                _ = win.getParent().sendMessage(df.ADDSTATUS, 0, 0);
            } else {
                ShowPosition(win);
            }
            return rtn;
        },
        df.KEYBOARD_CURSOR => {
            rtn = mp.zDefaultWndProc(win, msg, p1, p2);
            ShowPosition(win);
            return rtn;
        },
        df.COMMAND => {
            switch(p1) {
                df.ID_HELP => {
//                    const helpfile:[:0]const u8 = "MEMOPADDOC";
                    _ = mp.helpbox.DisplayHelp(win, "memopad");
                    return true;
                },
                df.ID_WRAP => {
                    _ = win.getParent().sendMessage(df.COMMAND, df.ID_WRAP, 0);
                    wnd.*.WordWrapMode = df.cfg.WordWrap;
                },
                df.ID_INSERT => {
                    _ = win.getParent().sendMessage(df.COMMAND, df.ID_INSERT, 0);
                    wnd.*.InsertMode = df.cfg.InsertMode;
                    _ = df.SendMessage(null, df.SHOW_CURSOR, wnd.*.InsertMode, 0);
                },
                else => {
                }
            }
        },
        df.CLOSE_WINDOW => {
            if (wnd.*.TextChanged > 0)    {
                _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);
                const tl:[*c]u8 = @ptrCast(wnd.*.title);
                const title = std.mem.span(tl);
                if (std.fmt.allocPrintSentinel(mp.global_allocator, "{s}\nText changed. Save it ?", .{title}, 0)) |m| {
                    defer mp.global_allocator.free(m);
                    if (mp.MessageBox.YesNoBox(m)) {
                        _ = win.getParent().sendMessage(df.COMMAND, df.ID_SAVE, 0);
                    }
                } else |_| {
                    // error
                }
            }
            wndpos = 0;
            if (wnd.*.extension != null)    {
                df.free(wnd.*.extension);
                wnd.*.extension = null;
            }
        },
        else => {
        }
    }
    return mp.zDefaultWndProc(win, msg, p1, p2);
}

// ------ display the row and column in the statusbar ------
fn ShowPosition(win:*mp.Window) void {
    const wnd = win.win;
    const l:u32 = @intCast(wnd.*.CurrLine);
    const c:u32 = @intCast(wnd.*.CurrCol);
    if (std.fmt.allocPrintSentinel(mp.global_allocator, "Line:{d:4} Column: {d:2}", .{l, c}, 0)) |m| {
        defer mp.global_allocator.free(m);
        _ = win.getParent().sendMessage(df.ADDSTATUS, @intCast(@intFromPtr(m.ptr)), 0);
    } else |_| {
        // error
    }
}

pub export fn PrepFileMenu(w:?*anyopaque, mnu:*df.Menu) callconv(.c) void {
    _ = mnu;
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_SAVE);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_SAVEAS);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_DELETEFILE);
    if (w) |ww| {
        const wnd:df.WINDOW = @ptrCast(@alignCast(ww));
        if (df.GetClass(wnd) == df.EDITBOX) {
            if (df.isMultiLine(wnd)>0) {
                mp.menu.ActivateCommand(&df.MainMenu, df.ID_SAVE);
                mp.menu.ActivateCommand(&df.MainMenu, df.ID_SAVEAS);
                mp.menu.ActivateCommand(&df.MainMenu, df.ID_DELETEFILE);
            }
        }
    }
}

pub export fn PrepEditMenu(w:?*anyopaque, mnu:*df.Menu) callconv(.c) void {
    _ = mnu;
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_CUT);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_COPY);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_CLEAR);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_DELETETEXT);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_PARAGRAPH);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_PASTE);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_UNDO);
    if (w) |ww| {
        const wnd:df.WINDOW = @ptrCast(@alignCast(ww));
        if (df.GetClass(wnd) == df.EDITBOX) {
           if (df.isMultiLine(wnd)>0) {
               if (df.TextBlockMarked(wnd)) {
                   mp.menu.ActivateCommand(&df.MainMenu, df.ID_CUT);
                   mp.menu.ActivateCommand(&df.MainMenu, df.ID_COPY);
                   mp.menu.ActivateCommand(&df.MainMenu, df.ID_CLEAR);
                   mp.menu.ActivateCommand(&df.MainMenu, df.ID_DELETETEXT);
               }
               mp.menu.ActivateCommand(&df.MainMenu, df.ID_PARAGRAPH);
               if ((df.TestAttribute(wnd, df.READONLY) == 0)) {
                   if (mp.clipboard.Clipboard) |_| {
                       mp.menu.ActivateCommand(&df.MainMenu, df.ID_PASTE);
                   }
               }
               if (wnd.*.DeletedText != null)
                   mp.menu.ActivateCommand(&df.MainMenu, df.ID_UNDO);
           }
        }
    }
}

pub export fn PrepSearchMenu(w:?*anyopaque, mnu:*df.Menu) void {
    _ = mnu;
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_SEARCH);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_REPLACE);
    mp.menu.DeactivateCommand(&df.MainMenu, df.ID_SEARCHNEXT);
    if (w) |ww| {
        const wnd:df.WINDOW = @ptrCast(@alignCast(ww));
        if (df.GetClass(wnd) == df.EDITBOX) {
            if (df.isMultiLine(wnd)>0) {
                mp.menu.ActivateCommand(&df.MainMenu, df.ID_SEARCH);
                mp.menu.ActivateCommand(&df.MainMenu, df.ID_REPLACE);
                mp.menu.ActivateCommand(&df.MainMenu, df.ID_SEARCHNEXT);
            }
        }
    }
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
