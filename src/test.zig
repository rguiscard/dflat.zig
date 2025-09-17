const std = @import("std");
const gapbuffer = @import("GapBuffer.zig");

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}

test {
    _ = gapbuffer;
    std.testing.refAllDecls(@This());
}
