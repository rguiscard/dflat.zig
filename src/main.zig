//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

extern fn c_main(argc: c_int, argv: [*][*:0]u8) void;

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);

    //    const argc: c_int = @intCast(std.os.argv.len);
    //    const argv = std.os.argv.ptr; // already C-compatible
    c_main(@intCast(args.len), @ptrCast(@constCast(args)));
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("dflat_zig_lib");
