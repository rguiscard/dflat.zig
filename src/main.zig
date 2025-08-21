//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

extern fn c_main(argc: c_int, argv: [*][*:0]u8) void;

pub fn main() !void {
    const argc: c_int = @intCast(std.os.argv.len);
    const argv = std.os.argv.ptr; // already C-compatible

    // Force zig to load, otherwise, it is lazy.
    _ = mp.dialogs.HelpBox;
    _ = mp.menus.SystemMenu;
    _ = mp.Window;
    _ = mp.Message;
    _ = mp.BarChart;
    _ = mp.Calendar;
    _ = mp.list;

    c_main(argc, argv);
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
