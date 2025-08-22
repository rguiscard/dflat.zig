//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub const DFlatApplication = "memopad";

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
    _ = mp.Watch;
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

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
const df = mp.df;
