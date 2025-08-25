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
    _ = mp.MessageBox;

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
                        mp.WndProc.MemoPadProc,
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

// --- open a document window and load a file ---
pub export fn OpenPadWindow(wnd: df.WINDOW, filename: [*c]const u8) void {
    const fname = std.mem.span(filename);
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
                null, wnd, mp.WndProc.OurEditorProc,
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
        _ = df.strcpy(ext, fname.ptr); // This could potentionally be a bug since fname may be long.

        df.LoadFile(win1.win);
    }

    _ = wwin.sendMessage(df.CLOSE_WINDOW, 0, 0);
    _ = win1.sendMessage(df.SETFOCUS, df.TRUE, 0);
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
