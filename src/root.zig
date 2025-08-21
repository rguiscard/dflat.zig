//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

pub const df = @import("ImportC.zig").df;
pub const dialogs = @import("Dialogs.zig");
pub const menus = @import("Menus.zig");
pub const Window = @import("Window.zig");
pub const Message = @import("Message.zig");

pub const global_allocator = std.heap.c_allocator;

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
