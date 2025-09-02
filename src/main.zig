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
    _ = mp.dialogs.HelpBox;
    _ = mp.menus.SystemMenu;
    _ = mp.Message;
    _ = mp.BarChart;
    _ = mp.Calendar;
    _ = mp.list;
    _ = mp.SystemMenu;

    if (df.init_messages() == df.FALSE) {
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
    while (df.dispatch_message()>0) {
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
                    df.DeleteFile(df.inFocus);
                    return true;
                },
                df.ID_EXIT => {
                    const m = "Exit Memopad?";
                    if (mp.MessageBox.YesNoBox(@constCast(m.ptr)) == df.FALSE)
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
                    _ = mp.MessageBox.MessageBox(@constCast(t.ptr), @constCast(m.ptr));
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
    const wnd = win.win;
    const fspec:[:0]const u8 = "*";
    var filename = std.mem.zeroes([df.MAXPATH]u8);

    if (mp.fileopen.OpenFileDialogBox(fspec, &filename)) {
        // --- see if the document is already in a window ---
        var wnd1:df.WINDOW = mp.Window.FirstWindow(wnd);
        while (wnd1 != null) {
            if (wnd1.*.extension) |extension| {
                const ext:[*c]const u8 = @ptrCast(extension);
                if (df.strcasecmp(&filename, ext) == 0) {
                    if (mp.Window.get_zin(wnd1)) |w| {
                        _ = w.sendMessage(df.SETFOCUS, df.TRUE, 0);
                        _ = w.sendMessage(df.RESTORE, 0, 0);
                    }
                    return;
                }
            }
            wnd1 = mp.Window.NextWindow(wnd1);
        }

        const fname = @as([*:0]u8, filename[0..filename.len-1:0]);
        OpenPadWindow(win, std.mem.span(fname));
    }
}

// --- open a document window and load a file ---
pub fn OpenPadWindow(win:*mp.Window, filename: []const u8) void {
    const wnd = win.win;
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
                null, wnd, OurEditorProc,
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
        win1.win.*.extension = df.DFmalloc(fname.len+1);
        const ext:[*c]u8 = @ptrCast(win1.win.*.extension);
        // wnd.extension is used to store filename.
        // it is also be used to compared already opened files.
        _ = df.strcpy(ext, fname.ptr); // may use std.mem.copyForwards in the future ?

        df.LoadFile(win1.win);
    }

    _ = wwin.sendMessage(df.CLOSE_WINDOW, 0, 0);
    _ = win1.sendMessage(df.SETFOCUS, df.TRUE, 0);
}

// ---------- save a file to disk ------------
fn SaveFile(win:*mp.Window, Saveas: bool) void {
    const wnd = win.win;
    const fspec:[:0]const u8 = "*";
    var filename = std.mem.zeroes([df.MAXPATH]u8);
    if ((wnd.*.extension == null) or (Saveas == true)) {
        if (mp.fileopen.SaveAsDialogBox(fspec, null, &filename)) {
            if (wnd.*.extension != df.NULL) {
                df.free(wnd.*.extension);
            }
            if (std.fs.cwd().realpathAlloc(mp.global_allocator, ".")) |_| {
                // should free
                wnd.*.extension = df.DFmalloc(df.strlen(&filename)+1);
                const ext:[*c]u8 = @ptrCast(wnd.*.extension);
                _ = df.strcpy(ext, &filename);
                df.AddTitle(wnd, df.NameComponent(&filename));
                _ = df.SendMessage(wnd, df.BORDER, 0, 0);
            } else |_| {
            }
        } else {
            return;
        }
    }
    if (wnd.*.extension != df.NULL) {
        const m:[]const u8 = "Saving the file";
        var mwin = mp.MessageBox.MomentaryMessage(m);

        const extension:[*c]u8 = @ptrCast(wnd.*.extension);
        const path:[:0]const u8 = std.mem.span(extension);
        const text:[*c]u8 = @ptrCast(wnd.*.text);
        const data:[]const u8 = std.mem.span(text);
        if (std.fs.cwd().writeFile(.{.sub_path = path, .data = data})) {
            wnd.*.TextChanged = df.FALSE;
        } else |_| {
        }

        _ = mwin.sendMessage(df.CLOSE_WINDOW, 0, 0);
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
                _ = df.SendMessage(mp.Window.GetParent(wnd), df.ADDSTATUS, 0, 0);
            } else {
                df.ShowPosition(wnd);
            }
            return rtn;
        },
        df.KEYBOARD_CURSOR => {
            rtn = mp.zDefaultWndProc(win, msg, p1, p2);
            df.ShowPosition(wnd);
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
                    _ = df.SendMessage(mp.Window.GetParent(wnd), df.COMMAND, df.ID_WRAP, 0);
                    wnd.*.WordWrapMode = df.cfg.WordWrap;
                },
                df.ID_INSERT => {
                    _ = df.SendMessage(mp.Window.GetParent(wnd), df.COMMAND, df.ID_INSERT, 0);
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
                    if (mp.MessageBox.YesNoBox(m) > 0) {
                        _ = df.SendMessage(mp.Window.GetParent(wnd), df.COMMAND, df.ID_SAVE, 0);
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

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
